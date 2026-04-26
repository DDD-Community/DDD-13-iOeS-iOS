import Foundation
import UIKit

protocol ExternalAppLauncherProtocol: Sendable {
    @MainActor
    func openNaverMapsRoute(latitude: Double, longitude: Double, name: String)
}

final class ExternalAppLauncher: ExternalAppLauncherProtocol, @unchecked Sendable {
    private let bundleIdentifierProvider: @Sendable () -> String

    init(
        bundleIdentifierProvider: @escaping @Sendable () -> String = { Bundle.main.bundleIdentifier ?? "pickflow" }
    ) {
        self.bundleIdentifierProvider = bundleIdentifierProvider
    }

    @MainActor
    func openNaverMapsRoute(latitude: Double, longitude: Double, name: String) {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let bundleIdentifier = bundleIdentifierProvider()
        let routeURL = URL(string: "nmap://route/public?dlat=\(latitude)&dlng=\(longitude)&dname=\(encodedName)&appname=\(bundleIdentifier)")
        let appStoreURL = URL(string: "https://apps.apple.com/kr/app/id311867728")

        guard let routeURL, let appStoreURL else { return }

        if UIApplication.shared.canOpenURL(URL(string: "nmap://")!) {
            UIApplication.shared.open(routeURL)
        } else {
            UIApplication.shared.open(appStoreURL)
        }
    }
}

@MainActor
func getExternalAppLauncher() -> ExternalAppLauncherProtocol {
    guard let launcher = DIContainerHolder.shared?.resolve(ExternalAppLauncherProtocol.self) else {
        fatalError("ExternalAppLauncherProtocol is not registered in DIContainer")
    }
    return launcher
}
