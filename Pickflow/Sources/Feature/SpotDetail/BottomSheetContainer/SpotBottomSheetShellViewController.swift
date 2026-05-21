import SwiftUI
import UIKit

// SwiftUI 콘텐츠를 UIHostingController로 호스팅하는 껍데기.
// 콘텐츠 자체는 phase를 모름. 컨테이너가 frame/chrome만 보간한다.
@MainActor
final class SpotBottomSheetShellViewController<Content: View>: UIViewController {

    let panCoordinator = SpotPanGestureCoordinator()
    weak var spotPresentationController: SpotPresentationController?

    private let hosting: UIHostingController<Content>

    init(rootView: Content) {
        self.hosting = UIHostingController(rootView: rootView)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "gray95") ?? UIColor(white: 0.07, alpha: 1)

        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.frame = view.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hosting.view.backgroundColor = .clear
        hosting.didMove(toParent: self)

        let pan = UIPanGestureRecognizer(
            target: panCoordinator,
            action: #selector(SpotPanGestureCoordinator.handlePan(_:))
        )
        pan.delegate = panCoordinator
        view.addGestureRecognizer(pan)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if panCoordinator.trackedScrollView == nil {
            panCoordinator.trackedScrollView = view.firstScrollView()
        }
    }
}

private extension UIView {
    func firstScrollView() -> UIScrollView? {
        if let s = self as? UIScrollView { return s }
        for sub in subviews {
            if let s = sub.firstScrollView() { return s }
        }
        return nil
    }
}
