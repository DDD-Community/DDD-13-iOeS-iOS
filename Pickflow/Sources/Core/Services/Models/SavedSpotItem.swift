import Foundation

struct SavedSpotItem: Decodable, Sendable, Identifiable, Equatable {
    let spotId: Int64
    let name: String
    @LenientSpotTheme var theme: SpotTheme?
    let imageUrl: String?
    let latitude: Double
    let longitude: Double
    let distanceKm: Double?
    let savedAt: String
    /// 등록자가 스팟 자체를 삭제한 경우.
    let deleted: Bool
    /// PV-40: 등록자가 공개를 해제했거나 아직 승인되지 않은 경우.
    /// 비공개면 서버가 `imageUrl` 을 null 로 마스킹해서 내려준다.
    var isPrivate: Bool?

    var id: Int64 { spotId }

    /// 등록자가 공개를 해제했거나 아직 승인되지 않은 상태.
    /// 이때 서버는 `imageUrl` 을 null 로 마스킹해 내려준다.
    var isPrivateSpot: Bool { isPrivate == true }

    /// 상세를 열 수 없는 상태. 서버가 삭제·비공개 스팟 조회를 404 로 막는다.
    var isUnavailable: Bool { deleted || isPrivateSpot }

    /// 썸네일 위에 얹을 안내. 열 수 있는 스팟이면 nil.
    /// 삭제가 비공개보다 되돌릴 수 없는 상태이므로 먼저 판단한다.
    var unavailableNotice: String? {
        if deleted { return "등록한 유저가\n삭제한 스팟이에요" }
        if isPrivateSpot { return "등록한 유저가\n비공개로 전환하였어요" }
        return nil
    }

    /// 셀 재사용을 위한 어댑터. 공개 여부·삭제 여부는 이 타입에만 있으므로
    /// 화면에서 필요하면 원본(SavedSpotItem)을 함께 넘겨야 한다.
    func toSpotListItem() -> SpotListItem {
        SpotListItem(
            spotId: spotId,
            name: name,
            theme: theme,
            thumbnailUrl: imageUrl,
            distanceKm: distanceKm,
            isBookmarked: true
        )
    }
}

struct SavedSpotPage: Decodable, Sendable, Equatable {
    let spots: [SavedSpotItem]
    let page: Int
    let hasNext: Bool
}
