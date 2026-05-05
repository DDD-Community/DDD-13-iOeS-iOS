import Foundation

protocol ShareIntentServiceProtocol: Sendable {
    func recordIntent(deviceId: String) async throws
}

@MainActor
func getShareIntentService() -> ShareIntentServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(ShareIntentServiceProtocol.self) else {
        fatalError("ShareIntentServiceProtocol is not registered in DIContainer")
    }
    return service
}
