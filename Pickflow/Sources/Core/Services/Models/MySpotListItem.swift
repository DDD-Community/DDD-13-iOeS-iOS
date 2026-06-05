import Foundation

enum MySpotStatus: String, Decodable, Sendable, Equatable {
    case pending = "PENDING"
    case published = "PUBLISHED"
    case rejected = "REJECTED"

    var displayName: String {
        switch self {
        case .pending: "검수 중"
        case .published: "공개"
        case .rejected: "반려"
        }
    }
}

struct MySpotListItem: Decodable, Sendable, Identifiable, Equatable {
    let spotId: Int64
    let name: String
    let theme: SpotTheme
    let imageUrl: String?
    let latitude: Double
    let longitude: Double
    let distanceKm: Double?
    let createdAt: String
    let status: MySpotStatus
    let bookmarkCount: Int

    var id: Int64 { spotId }

    /// SpotListCell 재사용을 위한 어댑터. isBookmarked 는 의미상 무관.
    func toSpotListItem() -> SpotListItem {
        SpotListItem(
            spotId: spotId,
            name: name,
            theme: theme,
            thumbnailUrl: imageUrl,
            distanceKm: distanceKm,
            isBookmarked: false
        )
    }
}

struct MySpotListPage: Decodable, Sendable, Equatable {
    let spots: [MySpotListItem]
    let page: Int
    let hasNext: Bool
}
