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

    /// 오버레이가 실제로 붙어 있는지. 씬을 못 찾아 무음 실패하는 경로를 테스트에서 잡기 위해 공개한다.
    var isAttached: Bool { overlayWindow != nil }

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
        recognizer.onEvent = { [weak self] event in
            self?.render(event)
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

    /// 활성 씬을 우선하되, 못 찾으면 윈도우를 가진 아무 씬이나 쓴다.
    /// 켰는데 아무 일도 일어나지 않는 것보다는 낫다.
    private var activeScene: UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive }
            ?? scenes.first { $0.keyWindow != nil }
    }

    // MARK: - 그리기

    /// 매 이벤트마다 `allTouches` 로 화면을 다시 맞춘다.
    ///
    /// 콜백으로 넘어오는 `touches` 는 "이번에 바뀐 것"뿐이라, 다른 제스처가 인식되는 등으로
    /// 끝을 놓치면 원이 남는다. 이벤트에 담긴 전체 터치를 기준으로 그리면 매번 스스로 교정된다.
    private func render(_ event: UIEvent) {
        guard let container = overlayWindow?.rootViewController?.view else { return }
        let touches = event.allTouches ?? []
        var active: Set<ObjectIdentifier> = []

        for touch in touches {
            let key = ObjectIdentifier(touch)

            switch touch.phase {
            case .began, .moved, .stationary:
                active.insert(key)
                let point = touch.location(in: nil)
                if let dot = dots[key] {
                    dot.center = point
                } else {
                    let dot = makeDot()
                    dot.center = point
                    container.addSubview(dot)
                    dots[key] = dot
                    // 손가락이 닿는 순간을 눈에 띄게 — 살짝 커졌다 제자리로.
                    dot.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
                    UIView.animate(withDuration: 0.12) { dot.transform = .identity }
                }

            default:
                continue
            }
        }

        // 끝났거나 이벤트에서 사라진 터치의 원은 걷어낸다.
        for (key, dot) in dots where !active.contains(key) {
            dots.removeValue(forKey: key)
            fadeOut(dot)
        }
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
    /// 바뀐 터치만이 아니라 이벤트를 통째로 넘긴다. 수신부가 allTouches 로 전체 상태를 다시 그린다.
    var onEvent: ((UIEvent) -> Void)?

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
        onEvent?(event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        onEvent?(event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        onEvent?(event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        onEvent?(event)
    }
}
