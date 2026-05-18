import UIKit

// 내부 스크롤이 최상단(offset <= 0)일 때만 시트 드래그를 인계받는다.
// (Apple 시스템 시트와 동일한 인터랙션 룰 — cooperate-with-scroll)
@MainActor
final class SpotPanGestureCoordinator: NSObject, UIGestureRecognizerDelegate {

    weak var trackedScrollView: UIScrollView?

    var onBegan: (() -> Void)?
    var onTranslation: ((CGFloat) -> Void)?
    var onEnded: ((CGFloat, CGFloat) -> Void)?

    @objc func handlePan(_ gr: UIPanGestureRecognizer) {
        let dy = gr.translation(in: gr.view).y
        switch gr.state {
        case .began:
            onBegan?()
        case .changed:
            onTranslation?(dy)
        case .ended, .cancelled:
            onEnded?(dy, gr.velocity(in: gr.view).y)
        default:
            break
        }
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool {
        other is UIPanGestureRecognizer
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let scroll = trackedScrollView else { return true }
        return scroll.contentOffset.y <= 0
    }
}
