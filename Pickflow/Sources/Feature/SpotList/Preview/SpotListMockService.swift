import Foundation

// FIXME(KAN-52 임시): BE 미오픈 기간 동안 시뮬레이터 검증용. PR 머지 전 또는 BE 오픈 시 제거하고
// AppContainer 등록을 `SpotListService(networkManager:)` 로 되돌릴 것.
final class SpotListMockService: SpotListServiceProtocol, Sendable {
    private static let pageSize = 8

    func fetchSpots(
        page: Int,
        themes: Set<SpotTheme>,
        sort _: SpotListSort,
        latitude _: Double?,
        longitude _: Double?,
        regionId _: Int?
    ) async throws -> SpotListPage {
        try await Task.sleep(for: .milliseconds(400))

        let filtered: [SpotListItem] = themes.isEmpty
            ? Self.allItems
            : Self.allItems.filter { item in item.theme.map(themes.contains) ?? false }

        let start = page * Self.pageSize
        guard start < filtered.count else {
            return SpotListPage(spots: [], page: page, hasNext: false)
        }
        let end = min(start + Self.pageSize, filtered.count)
        let slice = Array(filtered[start..<end])
        return SpotListPage(
            spots: slice,
            page: page,
            hasNext: end < filtered.count
        )
    }

    private static let allItems: [SpotListItem] = [
        SpotListItem(spotId: 1, name: "한강 노을길", theme: .sunset,
                     thumbnailUrl: nil, distanceKm: 0.4, isBookmarked: false),
        SpotListItem(spotId: 2, name: "잠실 윤슬", theme: .reflection,
                     thumbnailUrl: nil, distanceKm: 1.2, isBookmarked: false),
        SpotListItem(spotId: 3, name: "응봉산 전망대", theme: .sunset,
                     thumbnailUrl: nil, distanceKm: 2.0, isBookmarked: false),
        SpotListItem(spotId: 4, name: "반포 무지개 분수", theme: .reflection,
                     thumbnailUrl: nil, distanceKm: 2.8, isBookmarked: false),
        SpotListItem(spotId: 5, name: "선유도 일몰 포인트", theme: .sunset,
                     thumbnailUrl: nil, distanceKm: 3.5, isBookmarked: false),
        SpotListItem(spotId: 6, name: "광나루 윤슬길", theme: .reflection,
                     thumbnailUrl: nil, distanceKm: 4.1, isBookmarked: false),
        SpotListItem(spotId: 7, name: "노들섬 노을 뷰", theme: .sunset,
                     thumbnailUrl: nil, distanceKm: 4.7, isBookmarked: false),
        SpotListItem(spotId: 8, name: "성수 한강 윤슬", theme: .reflection,
                     thumbnailUrl: nil, distanceKm: 5.3, isBookmarked: false),
        SpotListItem(spotId: 9, name: "양화대교 노을", theme: .sunset,
                     thumbnailUrl: nil, distanceKm: 6.0, isBookmarked: false),
        SpotListItem(spotId: 10, name: "동작대교 윤슬", theme: .reflection,
                     thumbnailUrl: nil, distanceKm: 6.8, isBookmarked: false),
        SpotListItem(spotId: 11, name: "성산대교 노을", theme: .sunset,
                     thumbnailUrl: nil, distanceKm: 7.4, isBookmarked: false),
        SpotListItem(spotId: 12, name: "뚝섬 윤슬 산책로", theme: .reflection,
                     thumbnailUrl: nil, distanceKm: 8.2, isBookmarked: false),
    ]
}
