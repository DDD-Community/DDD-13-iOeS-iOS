import UIKit

/// 데모 촬영용 터치 표시. iOS 에는 화면 녹화 시 터치를 그려주는 기본 기능이 없어 직접 그린다.
///
/// 앱 위에 **터치를 통과시키는 오버레이 윈도우**를 하나 올리고, 실제 터치는 키 윈도우에 붙인
/// 제스처 인식기로 훔쳐본다. 인식기는 상태를 바꾸지 않고 `cancelsTouchesInView` 도 꺼서
/// 기존 탭·스크롤·스와이프 동작에 개입하지 않는다.
@MainActor
final class TouchIndicatorPresenter {
    static let shared = TouchIndicatorPresenter()

    private var overlayWindow: UIWindow?
    private var recognizer: TouchObservingGestureRecognizer?
    private var dots: [ObjectIdentifier: UIView] = [:]

    private let diameter: CGFloat = 44

    private init() {}

    func setEnabled(_ enabled: Bool) {
        enabled ? attach() : detach()
    }

    // MARK: - 부착 / 해제

    private func attach() {
        guard overlayWindow == nil, let scene = activeScene, let keyWindow = scene.keyWindow else { return }

        let window = PassthroughWindow(windowScene: scene)
        window.backgroundColor = .clear
        window.isUserInteractionEnabled = false
        // 시트·알럿 위에서도 보이도록 가장 위에 둔다.
        window.windowLevel = .alert + 1
        window.rootViewController = TransparentRootViewController()
        window.isHidden = false
        overlayWindow = window

        let recognizer = TouchObservingGestureRecognizer()
        recognizer.onChange = { [weak self] touches in
            self?.render(touches)
        }
        // 스크롤처럼 다른 제스처가 인식되면 touchesEnded 대신 reset 만 불린다.
        // 이때 정리하지 않으면 원이 화면에 남는다.
        recognizer.onReset = { [weak self] in
            self?.clearAllDots()
        }
        keyWindow.addGestureRecognizer(recognizer)
        self.recognizer = recognizer
    }

    private func detach() {
        recognizer?.view?.removeGestureRecognizer(recognizer!)
        recognizer = nil
        dots.values.forEach { $0.removeFromSuperview() }
        dots.removeAll()
        overlayWindow?.isHidden = true
        overlayWindow = nil
    }

    private var activeScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }

    // MARK: - 그리기

    private func render(_ touches: Set<UITouch>) {
        guard let container = overlayWindow?.rootViewController?.view else { return }

        for touch in touches {
            let key = ObjectIdentifier(touch)
            let point = touch.location(in: nil)

            switch touch.phase {
            case .began:
                // UITouch 인스턴스는 재사용된다. 같은 키에 덮어쓰면 이전 뷰가 화면에 남으므로 먼저 걷어낸다.
                dots.removeValue(forKey: key)?.removeFromSuperview()

                let dot = makeDot()
                dot.center = point
                container.addSubview(dot)
                dots[key] = dot
                // 손가락이 닿는 순간을 눈에 띄게 — 살짝 커졌다 제자리로.
                dot.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
                UIView.animate(withDuration: 0.12) { dot.transform = .identity }

            case .moved, .stationary:
                dots[key]?.center = point

            case .ended, .cancelled:
                guard let dot = dots.removeValue(forKey: key) else { continue }
                fadeOut(dot)

            default:
                continue
            }
        }
    }

    /// 남아 있는 원을 모두 걷어낸다. 터치 시퀀스가 끝났는데 정리되지 않은 경우의 안전망.
    private func clearAllDots() {
        let leftovers = dots.values
        dots.removeAll()
        leftovers.forEach { fadeOut($0) }
    }

    private func fadeOut(_ dot: UIView) {
        UIView.animate(withDuration: 0.18) {
            dot.alpha = 0
            dot.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        } completion: { _ in
            dot.removeFromSuperview()
        }
    }

    private func makeDot() -> UIView {
        let dot = UIView(frame: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        dot.backgroundColor = UIColor.white.withAlphaComponent(0.35)
        dot.layer.cornerRadius = diameter / 2
        dot.layer.borderWidth = 1.5
        dot.layer.borderColor = UIColor.white.withAlphaComponent(0.9).cgColor
        dot.isUserInteractionEnabled = false
        return dot
    }
}

// MARK: - 보조 타입

/// 터치를 아래 화면으로 그대로 흘려보내는 윈도우.
private final class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { nil }
}

private final class TransparentRootViewController: UIViewController {
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        self.view = view
    }

    override var prefersStatusBarHidden: Bool { true }
}

/// 터치를 관찰만 하고 인식하지 않는 제스처 인식기.
/// 상태를 바꾸지 않으므로 다른 제스처와 경쟁하지 않는다.
private final class TouchObservingGestureRecognizer: UIGestureRecognizer {
    var onChange: ((Set<UITouch>) -> Void)?
    /// 터치 시퀀스가 끝날 때 항상 불린다. 다른 제스처가 인식돼 touchesEnded 를 못 받는 경우까지 잡는다.
    var onReset: (() -> Void)?

    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
        requiresExclusiveTouchType = false
    }

    convenience init() {
        self.init(target: nil, action: nil)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        onChange?(touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        onChange?(touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        onChange?(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        onChange?(touches)
    }

    override func reset() {
        super.reset()
        onReset?()
    }
}
