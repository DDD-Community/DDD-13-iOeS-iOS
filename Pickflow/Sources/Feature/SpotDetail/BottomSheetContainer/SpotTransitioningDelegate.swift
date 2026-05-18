import UIKit

@MainActor
final class SpotTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    weak var presentationController: SpotPresentationController?

    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        let pc = SpotPresentationController(presentedViewController: presented, presenting: presenting)
        presentationController = pc
        return pc
    }
}
