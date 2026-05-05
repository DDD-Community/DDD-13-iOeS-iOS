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
              let rootViewController = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return }

        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        rootViewController.present(activityViewController, animated: true)
    }
}

@MainActor
func getShareSheetPresenter() -> ShareSheetPresenterProtocol {
    guard let presenter = DIContainerHolder.shared?.resolve(ShareSheetPresenterProtocol.self) else {
        fatalError("ShareSheetPresenterProtocol is not registered in DIContainer")
    }
    return presenter
}
