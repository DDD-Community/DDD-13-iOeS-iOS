import Foundation

protocol SpotListServiceProtocol: Sendable {
    /// 스팟 리스트 페이지를 조회한다.
    /// - Parameters:
    ///   - page: 0-based 페이지
    ///   - themes: 카테고리 필터(다중선택). 비어 있으면 전체
    ///   - latitude/longitude: 거리 계산용. `nil` 이면 `distanceKm` 가 `nil` 로 응답
    func fetchSpots(
        page: Int,
        themes: Set<SpotTheme>,
        sort: SpotListSort,
        latitude: Double?,
        longitude: Double?,
        regionId: Int?
    ) async throws -> SpotListPage
}

@MainActor
func getSpotListService() -> SpotListServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(SpotListServiceProtocol.self) else {
        fatalError("SpotListServiceProtocol is not registered in DIContainer")
    }
    return service
}
