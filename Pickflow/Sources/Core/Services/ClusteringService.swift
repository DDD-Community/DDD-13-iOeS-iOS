import Foundation

final class ClusteringService: ClusteringServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func fetchSpots(viewport: Viewport, themes: Set<SpotTheme>) async throws -> (curation: [ClusterableSpot], mySpots: [MySpot]) {
        let summaries = try await fetchViewport(viewport: viewport, themes: themes)
        var curation: [ClusterableSpot] = []
        var mySpots: [MySpot] = []
        curation.reserveCapacity(summaries.count)
        for summary in summaries {
            if summary.isMySpot {
                mySpots.append(MySpot(id: summary.spotId, coordinate: summary.coordinate, imageUrl: summary.spotImageUrl))
            } else {
                curation.append(ClusterableSpot(id: summary.spotId, coordinate: summary.coordinate, imageUrl: summary.spotImageUrl))
            }
        }
        return (curation, mySpots)
    }

    private func fetchViewport(viewport: Viewport, themes: Set<SpotTheme>) async throws -> [SpotSummary] {
        let envelope: APIEnvelope<SpotViewportResponse> = try await networkManager.request(
            endpoint: SpotViewportEndpoint(
                viewport: viewport,
                themes: themes
            )
        )
        return envelope.data.spots
    }
}
