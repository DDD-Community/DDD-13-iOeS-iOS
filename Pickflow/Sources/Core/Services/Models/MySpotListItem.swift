import Foundation

/// 유저 등록 스팟의 공개 상태.
/// 등록 직후 `draft`(나만보기)이며, 오픈 신청 시 `pending`,
/// 반려 후 재신청 시 `reReviewPending`으로 전이된다.
enum MySpotStatus: String, Sendable, Equatable, CaseIterable {
    case draft = "DRAFT"
    case pending = "PENDING"
    case reReviewPending = "RE_REVIEW_PENDING"
    case published = "PUBLISHED"
    case rejected = "REJECTED"

    /// 서버가 아직 모르는 상태를 내려줘도 목록 전체가 깨지지 않도록 두는 폴백.
    case unknown

    var displayName: String {
        switch self {
        case .draft: "나만보기"
        case .pending, .reReviewPending: "검수 중"
        case .published: "공개"
        case .rejected: "반려"
        case .unknown: "-"
        }
    }

    /// 검수 결과를 기다리는 중인지. 이 상태에서는 삭제·수정이 막힌다(SP010/SP011).
    var isUnderReview: Bool {
        self == .pending || self == .reReviewPending
    }
}

extension MySpotStatus: Codable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = MySpotStatus(rawValue: raw) ?? .unknown
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
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
