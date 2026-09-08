import Foundation

/// 스팟 미리보기(`/v1/spots/{spotId}/preview`) 응답. 바텀시트 medium 상태에서 사용.
struct SpotPreviewResponse: Codable, Sendable, Identifiable, Equatable {
    let spotId: Int64
    let name: String
    let isMySpot: Bool
    @LenientSpotTheme var theme: SpotTheme?
    let bookmarkCount: Int
    let isBookmarked: Bool
    let distanceKm: Double?
    let imageUrl: String?
    let addressSimple: String
    let addressRoad: String?
    let addressJibun: String?

    // MARK: - PV-40
    var isCurated: Bool?
    var likeCount: Int?
    var isLiked: Bool?
    var isLikeable: Bool?

    var id: Int64 { spotId }
}
