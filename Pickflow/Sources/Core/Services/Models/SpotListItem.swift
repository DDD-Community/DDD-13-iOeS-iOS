import Foundation

struct SpotListItem: Codable, Sendable, Identifiable, Equatable {
    let spotId: Int64
    let name: String
    let theme: SpotTheme
    let thumbnailUrl: String?
    let distanceKm: Double?

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
