import Foundation

/// 나만의 스팟 공개 상태. 서버 값과 1:1.
enum MySpotStatus: String, Sendable, Equatable {
    case draft = "DRAFT"
    case pending = "PENDING"
    case reReviewPending = "RE_REVIEW_PENDING"
    case published = "PUBLISHED"
    case rejected = "REJECTED"
    /// 서버가 새 상태를 추가해도 목록 전체가 깨지지 않도록 두는 자리.
    case unknown

    /// 카드 뱃지 표기. 나만보기와 미지의 상태는 뱃지를 달지 않는다.
    ///
    /// 재검토 대기는 어드민 쪽 구분일 뿐이라 유저에게는 검수중과 똑같이 보인다.
    /// (기획: "반려 후 재신청 → 다시 검수중 상태로 전환")
    var badgeText: String? {
        switch self {
        case .draft, .unknown: nil
        case .pending, .reReviewPending: "검수 중"
        case .published: "공개"
        case .rejected: "오픈 반려"
        }
    }
}

extension MySpotStatus: Decodable {
    /// 모르는 값이 오면 그 스팟 하나가 아니라 목록 전체 디코딩이 실패한다.
    /// 상태는 표시용이므로 알 수 없는 값은 `unknown` 으로 흘려보낸다.
    init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = MySpotStatus(rawValue: raw) ?? .unknown
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
