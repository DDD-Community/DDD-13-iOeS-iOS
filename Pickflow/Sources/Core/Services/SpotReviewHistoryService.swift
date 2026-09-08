import Foundation

final class SpotReviewHistoryService: SpotReviewHistoryServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func fetchUncheckedHistories() async throws -> SpotReviewHistoryList {
        let envelope: APIEnvelope<SpotReviewHistoryList> = try await networkManager.request(
            endpoint: SpotReviewHistoryEndpoint.fetchUnchecked
        )
        return envelope.data
    }

    func markChecked(historyId: Int64) async throws {
        let _: APIEnvelope<SpotReviewHistoryCheckResponse> = try await networkManager.request(
            endpoint: SpotReviewHistoryEndpoint.checkStatus(historyId: historyId)
        )
    }
}
