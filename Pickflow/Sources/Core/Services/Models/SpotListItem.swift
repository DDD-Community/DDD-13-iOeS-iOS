import Foundation

struct SpotListItem: Codable, Sendable, Identifiable, Equatable {
    let spotId: Int64
    let name: String
    let theme: SpotTheme
    let thumbnailUrl: String?
    let distanceKm: Double?

    var id: Int64 { spotId }

    // FIXME(BE-API): 응답에 bookmarkCount / isBookmarked 가 추가되면 필드로 승격한다.
    //                현 단계에서는 ViewModel 측 bookmarkStates 로 임시 관리한다.

    init(
        spotId: Int64,
        name: String,
        theme: SpotTheme,
        thumbnailUrl: String?,
        distanceKm: Double?
    ) {
        self.spotId = spotId
        self.name = name
        self.theme = theme
        self.thumbnailUrl = thumbnailUrl
        self.distanceKm = distanceKm
    }

    private enum CodingKeys: String, CodingKey {
        case spotId, name, theme, thumbnailUrl, distanceKm
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.spotId = try container.decode(Int64.self, forKey: .spotId)
        self.name = try container.decode(String.self, forKey: .name)
        let themeCode = try container.decode(String.self, forKey: .theme)
        guard let theme = SpotTheme(apiCode: themeCode) else {
            throw DecodingError.dataCorruptedError(
                forKey: .theme,
                in: container,
                debugDescription: "Unknown SpotTheme apiCode: \(themeCode)"
            )
        }
        self.theme = theme
        self.thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        self.distanceKm = try container.decodeIfPresent(Double.self, forKey: .distanceKm)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(spotId, forKey: .spotId)
        try container.encode(name, forKey: .name)
        try container.encode(theme.apiCode, forKey: .theme)
        try container.encodeIfPresent(thumbnailUrl, forKey: .thumbnailUrl)
        try container.encodeIfPresent(distanceKm, forKey: .distanceKm)
    }
}

struct SpotListPage: Codable, Sendable, Equatable {
    let spots: [SpotListItem]
    let page: Int
    let hasNext: Bool
}

extension SpotTheme {
    var apiCode: String {
        switch self {
        case .sunset: "SUNSET"
        case .reflection: "YUNSEUL"
        }
    }

    init?(apiCode: String) {
        switch apiCode {
        case "노을": self = .sunset
        case "윤슬": self = .reflection
        default: return nil
        }
    }
}

enum SpotListSort: String, Sendable, CaseIterable, Equatable {
    case nearest
    case bookmark

    var displayName: String {
        switch self {
        case .nearest: "가까운 순"
        case .bookmark: "북마크 순"
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
