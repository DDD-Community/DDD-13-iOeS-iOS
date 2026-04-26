import Foundation

final class SpotService: SpotServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func fetchSpotDetail(id: Int64, latitude: Double?, longitude: Double?) async throws -> SpotDetail {
        try await networkManager.request(endpoint: SpotEndpoint(id: id, latitude: latitude, longitude: longitude))
    }
}
