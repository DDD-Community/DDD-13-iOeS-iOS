import Foundation

final class AppVersionService: AppVersionServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func fetchIOSVersionPolicy() async throws -> AppVersionPolicy {
        let response: ApiResponse<AppVersionPolicy> = try await networkManager.requestJSON(
            endpoint: AppVersionEndpoint.iOS
        )
        return response.data
    }
}
