import Foundation

final class RegionService: RegionServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func fetchActiveRegions() async throws -> [Region] {
        let envelope: APIEnvelope<RegionListResponse> = try await networkManager.request(
            endpoint: RegionEndpoint.activeList
        )
        return envelope.data.regions
    }
}
