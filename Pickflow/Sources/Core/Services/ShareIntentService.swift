import Foundation

final class ShareIntentService: ShareIntentServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func recordIntent(deviceId: String) async throws {
        let _: EmptyResponse = try await networkManager.request(endpoint: ShareIntentEndpoint(deviceId: deviceId))
    }
}
