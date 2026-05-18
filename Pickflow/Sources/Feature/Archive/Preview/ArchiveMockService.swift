import Foundation

// FIXME(KAN-53 임시): BE 미오픈 기간 동안 시뮬레이터 검증용.
// BE 오픈 시 AppContainer 등록을 ArchiveService(networkManager:)로 교체할 것.
final class ArchiveMockService: ArchiveServiceProtocol, Sendable {
    private static let pageSize = 8

    func fetchArchive(page: Int) async throws -> SpotListPage {
        try await Task.sleep(for: .milliseconds(400))

        let start = page * Self.pageSize
        guard start < Self.allItems.count else {
            return SpotListPage(spots: [], page: page, hasNext: false)
        }
        let end = min(start + Self.pageSize, Self.allItems.count)
        let slice = Array(Self.allItems[start..<end])
        return SpotListPage(spots: slice, page: page, hasNext: end < Self.allItems.count)
    }

    private static let allItems: [SpotListItem] = [
        SpotListItem(spotId: 1, name: "한강 노을길", theme: .sunset, thumbnailUrl: nil, distanceKm: 0.4),
        SpotListItem(spotId: 2, name: "잠실 윤슬", theme: .reflection, thumbnailUrl: nil, distanceKm: 1.2),
        SpotListItem(spotId: 3, name: "응봉산 전망대", theme: .sunset, thumbnailUrl: nil, distanceKm: 2.0),
        SpotListItem(spotId: 4, name: "반포 무지개 분수", theme: .reflection, thumbnailUrl: nil, distanceKm: 2.8),
        SpotListItem(spotId: 5, name: "선유도 일몰 포인트", theme: .sunset, thumbnailUrl: nil, distanceKm: 3.5),
        SpotListItem(spotId: 6, name: "광나루 윤슬길", theme: .reflection, thumbnailUrl: nil, distanceKm: 4.1),
        SpotListItem(spotId: 7, name: "노들섬 노을 뷰", theme: .sunset, thumbnailUrl: nil, distanceKm: 4.7),
        SpotListItem(spotId: 8, name: "성수 한강 윤슬", theme: .reflection, thumbnailUrl: nil, distanceKm: 5.3),
        SpotListItem(spotId: 9, name: "양화대교 노을", theme: .sunset, thumbnailUrl: nil, distanceKm: 6.0),
        SpotListItem(spotId: 10, name: "동작대교 윤슬", theme: .reflection, thumbnailUrl: nil, distanceKm: 6.8),
    ]
}
