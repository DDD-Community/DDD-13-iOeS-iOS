import Foundation

// FIXME(KAN-53 임시): BE 미오픈 기간 동안 시뮬레이터 검증용.
// BE 오픈 시 AppContainer 등록을 ArchiveService(networkManager:)로 교체할 것.
final class ArchiveMockService: ArchiveServiceProtocol, Sendable {
    private static let pageSize = 8

    func fetchArchiveInfo() async throws -> ArchiveInfo {
        try await Task.sleep(for: .milliseconds(200))
        return ArchiveInfo(archiveName: "나의 보관함", archiveImageUrl: nil)
    }

    func renameArchive(_ name: String) async throws -> ArchiveInfo {
        try await Task.sleep(for: .milliseconds(200))
        return ArchiveInfo(archiveName: name, archiveImageUrl: nil)
    }

    func uploadArchiveImage(_ data: Data) async throws -> ArchiveInfo {
        try await Task.sleep(for: .milliseconds(300))
        return ArchiveInfo(archiveName: "나의 보관함", archiveImageUrl: nil)
    }

    func fetchSavedSpots(page: Int, latitude: Double?, longitude: Double?) async throws -> SavedSpotPage {
        try await Task.sleep(for: .milliseconds(400))

        let start = page * Self.pageSize
        guard start < Self.allItems.count else {
            return SavedSpotPage(spots: [], page: page, hasNext: false)
        }
        let end = min(start + Self.pageSize, Self.allItems.count)
        let slice = Array(Self.allItems[start..<end])
        return SavedSpotPage(spots: slice, page: page, hasNext: end < Self.allItems.count)
    }

    func fetchMySpots(page: Int, latitude: Double?, longitude: Double?) async throws -> MySpotListPage {
        try await Task.sleep(for: .milliseconds(400))
        return MySpotListPage(spots: [], page: page, hasNext: false)
    }

    private static let allItems: [SavedSpotItem] = [
        makeSavedSpotItem(spotId: 1, name: "한강 노을길", theme: .sunset, distanceKm: 0.4),
        makeSavedSpotItem(spotId: 2, name: "잠실 윤슬", theme: .reflection, distanceKm: 1.2, isPrivate: true),
        makeSavedSpotItem(spotId: 3, name: "응봉산 전망대", theme: .sunset, distanceKm: 2.0, deleted: true),
        makeSavedSpotItem(spotId: 4, name: "반포 무지개 분수", theme: .reflection, distanceKm: 2.8),
        makeSavedSpotItem(spotId: 5, name: "선유도 일몰 포인트", theme: .sunset, distanceKm: 3.5),
        makeSavedSpotItem(spotId: 6, name: "광나루 윤슬길", theme: .reflection, distanceKm: 4.1, deleted: true),
        makeSavedSpotItem(spotId: 7, name: "노들섬 노을 뷰", theme: .sunset, distanceKm: 4.7),
        makeSavedSpotItem(spotId: 8, name: "성수 한강 윤슬", theme: .reflection, distanceKm: 5.3),
        makeSavedSpotItem(spotId: 9, name: "양화대교 노을", theme: .sunset, distanceKm: 6.0),
        makeSavedSpotItem(spotId: 10, name: "동작대교 윤슬", theme: .reflection, distanceKm: 6.8),
    ]
}

/// 프리뷰용 저장 스팟 픽스처. 비공개/삭제 상태를 섞어 볼 수 있게 인자로 뺐다.
func makeSavedSpotItem(
    spotId: Int64,
    name: String,
    theme: SpotTheme?,
    distanceKm: Double?,
    likeCount: Int? = 34,
    deleted: Bool = false,
    isPrivate: Bool? = nil
) -> SavedSpotItem {
    SavedSpotItem(
        spotId: spotId,
        name: name,
        theme: theme,
        imageUrl: nil,
        latitude: 37.5,
        longitude: 127.0,
        distanceKm: distanceKm,
        likeCount: likeCount,
        savedAt: "2026-08-01T00:00:00Z",
        deleted: deleted,
        isPrivate: isPrivate
    )
}
