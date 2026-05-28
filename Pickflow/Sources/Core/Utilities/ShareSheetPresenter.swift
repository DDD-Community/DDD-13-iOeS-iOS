import Foundation
import SwiftUI
import UIKit

protocol ShareSheetPresenterProtocol: Sendable {
    @MainActor
    func present(items: [String])
}

@MainActor
final class ShareSheetPresenter: ShareSheetPresenterProtocol {
    func present(items: [String]) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return }

        let top = topMost(of: root)
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        top.present(activityViewController, animated: true)
    }

    private func topMost(of viewController: UIViewController) -> UIViewController {
        if let presented = viewController.presentedViewController {
            return topMost(of: presented)
        }
        return viewController
    }
}

@MainActor
func getShareSheetPresenter() -> ShareSheetPresenterProtocol {
    guard let presenter = DIContainerHolder.shared?.resolve(ShareSheetPresenterProtocol.self) else {
        fatalError("ShareSheetPresenterProtocol is not registered in DIContainer")
    }
    return presenter
}
