import Foundation

struct SpotListItem: Codable, Sendable, Identifiable, Equatable {
    let spotId: Int64
    let name: String
    @LenientSpotTheme var theme: SpotTheme?
    let thumbnailUrl: String?
    let distanceKm: Double?
    let isBookmarked: Bool

    // MARK: - PV-40
    // 서버가 아직 안 내려주거나 비로그인이면 nil 이다.
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
        // 서버 RECOMMENDED 정렬 기준이 bookmark_count → like_count 로 바뀌었다.
        case .recommended: "추천 순"
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
