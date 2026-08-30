import Foundation

struct SavedSpotItem: Decodable, Sendable {
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

    func toSpotListItem() -> SpotListItem {
        SpotListItem(spotId: spotId, name: name, theme: theme, thumbnailUrl: imageUrl, distanceKm: distanceKm, isBookmarked: true)
    }
}

struct SavedSpotPage: Decodable, Sendable {
    let spots: [SavedSpotItem]
    let page: Int
    let hasNext: Bool
}
