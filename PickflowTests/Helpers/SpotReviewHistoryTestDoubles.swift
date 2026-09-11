import Foundation
@testable import Pickflow

final class MockSpotReviewHistoryService: SpotReviewHistoryServiceProtocol, @unchecked Sendable {
    var historiesResult: Result<SpotReviewHistoryList, any Error> = .success(
        SpotReviewHistoryList(approved: [], rejected: [])
    )
    var checkError: (any Error)?

    private(set) var checkedHistoryIds: [Int64] = []

    func fetchUncheckedHistories() async throws -> SpotReviewHistoryList {
        try historiesResult.get()
    }

    func markChecked(historyId: Int64) async throws {
        checkedHistoryIds.append(historyId)
        if let checkError { throw checkError }
    }
}
