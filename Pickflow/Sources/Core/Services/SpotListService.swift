import Foundation

final class SpotListService: SpotListServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func fetchSpots(
        page: Int,
        theme: SpotTheme?,
        sort: SpotListSort,
        latitude: Double?,
        longitude: Double?
    ) async throws -> SpotListPage {
        let envelope: APIEnvelope<SpotListPage> = try await networkManager.request(
            endpoint: SpotListEndpoint(
                page: page,
                theme: theme,
                sort: sort,
                latitude: latitude,
                longitude: longitude
            )
        )
        return envelope.data
    }
}
