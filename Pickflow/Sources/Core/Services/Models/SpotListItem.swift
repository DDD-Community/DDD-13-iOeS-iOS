import Foundation

struct SpotListItem: Codable, Sendable, Identifiable, Equatable {
    let spotId: Int64
    let name: String
    let theme: SpotTheme
    let thumbnailUrl: String?
    let distanceKm: Double?
    let isBookmarked: Bool

    // MARK: - PV-40
    var likeCount: Int?
    var isLiked: Bool?

    var id: Int64 { spotId }
}

struct SpotListPage: Codable, Sendable, Equatable {
    let spots: [SpotListItem]
    let page: Int
    let hasNext: Bool
}

enum SpotListSort: String, Sendable, CaseIterable, Equatable {
    case distance
    case recommended

    var displayName: String {
        switch self {
        case .distance: "가까운 순"
        // TODO(PV-40): 서버의 RECOMMENDED 정렬 기준이 bookmark_count → like_count 로 바뀌었으므로
        //              라벨도 "추천 순"으로 바꿔야 한다. 스냅샷 레퍼런스 재기록이 필요해 UI 단계에서 함께 처리.
        case .recommended: "북마크 순"
        }
    }

    var apiCode: String {
        switch self {
        case .distance: "DISTANCE"
        case .recommended: "RECOMMENDED"
        }
    }
}

/// 서버 공통 응답 envelope.
struct APIEnvelope<T: Decodable & Sendable>: Decodable, Sendable where T: Sendable {
    let success: Bool
    let code: String
    let message: String
    let data: T
}
