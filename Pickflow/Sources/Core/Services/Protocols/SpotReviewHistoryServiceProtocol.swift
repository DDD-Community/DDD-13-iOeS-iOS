import Foundation

/// 검수완료 알림 히스토리 조회/확인. (PV-40)
protocol SpotReviewHistoryServiceProtocol: Sendable {
    func fetchUncheckedHistories() async throws -> SpotReviewHistoryList

    /// 멱등 — 이미 확인된 히스토리를 다시 요청해도 에러 없이 성공한다.
    func markChecked(historyId: Int64) async throws
}

@MainActor
func getSpotReviewHistoryService() -> SpotReviewHistoryServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(SpotReviewHistoryServiceProtocol.self) else {
        fatalError("SpotReviewHistoryServiceProtocol is not registered in DIContainer")
    }
    return service
}
