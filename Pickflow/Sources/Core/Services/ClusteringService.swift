import Foundation

final class ClusteringService: ClusteringServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func fetchClusterableSpots(viewport: Viewport, theme: String?) async throws -> [ClusterableSpot] {
        let summaries = try await fetchViewport(viewport: viewport, theme: theme)
        return summaries
            .filter { !$0.isMySpot }
            .map { ClusterableSpot(id: $0.spotId, coordinate: $0.coordinate, imageUrl: $0.spotImageUrl) }
    }

    func fetchMySpots(viewport: Viewport) async throws -> [MySpot] {
        let summaries = try await fetchViewport(viewport: viewport, theme: nil)
        return summaries
            .filter(\.isMySpot)
            .map { MySpot(id: $0.spotId, coordinate: $0.coordinate, imageUrl: $0.spotImageUrl) }
    }

    private func fetchViewport(viewport: Viewport, theme: String?) async throws -> [SpotSummary] {
        let envelope: APIEnvelope<SpotViewportResponse> = try await networkManager.request(
            endpoint: SpotViewportEndpoint(
                viewport: viewport,
                theme: theme.flatMap(SpotTheme.init(apiCode:))
            )
        )
        return envelope.data.spots
    }
}
