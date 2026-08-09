import Foundation

struct SpotDetail: Codable, Sendable, Identifiable, Equatable {
    let spotId: Int64
    let name: String
    let comment: String
    let theme: SpotTheme
    let latitude: Double
    let longitude: Double
    let address: String
    let imageUrl: String?
    let recordedDate: String?
    let recordedTime: String?
    let weatherSky: WeatherSky?
    let precipitation: Precipitation?
    let precipitationProbability: Int?
    let congestionLevel: CongestionLevel?
    let sunsetTime: String?
    let astronomyDate: String?
    let weatherUpdatedAt: String?
    let congestionUpdatedAt: String?
    let parkingInfo: String?
    let bookmarkCount: Int
    let isBookmarked: Bool
    let isMySpot: Bool

    var id: Int64 { spotId }

    /// 현재 날씨 표시용 — 강수가 있으면 강수 종류, 없으면 하늘 상태.
    var weatherDisplayName: String? {
        if let precipitation, precipitation != .none {
            return precipitation.displayName
        }
        return weatherSky?.displayName
    }
}

/// 사진 카테고리. `allCases` 순서가 곧 화면 노출 순서(햇살/윤슬/노을/야경)다.
enum SpotTheme: String, Sendable, Equatable, CaseIterable {
    case sunlight = "햇살"
    case reflection = "윤슬"
    case sunset = "노을"
    case nightView = "야경"
}

extension SpotTheme: Codable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let code = try container.decode(String.self)
        guard let theme = SpotTheme(apiCode: code) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown SpotTheme apiCode: \(code)"
            )
        }
        self = theme
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(apiCode)
    }
}

extension SpotTheme {
    // TODO(BE-API): 햇살/야경 서버 enum 값 확정 시 SUNLIGHT / NIGHT_VIEW 교체.
    var apiCode: String {
        switch self {
        case .sunlight: "SUNLIGHT"
        case .reflection: "YUNSEUL"
        case .sunset: "SUNSET"
        case .nightView: "NIGHT_VIEW"
        }
    }

    init?(apiCode: String) {
        switch apiCode {
        case "SUNLIGHT", "SL": self = .sunlight
        case "YUNSEUL", "YS": self = .reflection
        case "SUNSET", "SS": self = .sunset
        case "NIGHT_VIEW", "NV": self = .nightView
        default: return nil
        }
    }

    /// 표시명. rawValue 가 곧 한글 표기다.
    var displayName: String { rawValue }

    /// 카테고리 아이콘 에셋. 탐색 필터 칩·등록폼 칩·리스트 셀 오버레이가 공유한다.
    var iconAssetName: String {
        switch self {
        case .sunlight: "icon_photo_category_sunlight"
        case .reflection: "icon_photo_category_reflection"
        case .sunset: "icon_photo_category_sunset"
        case .nightView: "icon_photo_category_nightview"
        }
    }

    /// 에셋 누락 시 AssetImage 가 쓰는 폴백.
    var iconEmoji: String {
        switch self {
        case .sunlight: "☀️"
        case .reflection: "🌊"
        case .sunset: "🌇"
        case .nightView: "🌙"
        }
    }
}

enum WeatherSky: String, Codable, Sendable, Equatable {
    case clear = "CLEAR"
    case mostlyCloudy = "MOSTLY_CLOUDY"
    case overcast = "OVERCAST"

    var displayName: String {
        switch self {
        case .clear: "맑음"
        case .mostlyCloudy: "구름 많음"
        case .overcast: "흐림"
        }
    }
}

enum Precipitation: String, Codable, Sendable, Equatable {
    case none = "NONE"
    case rain = "RAIN"
    case rainSnow = "RAIN_SNOW"
    case snow = "SNOW"
    case shower = "SHOWER"

    var displayName: String {
        switch self {
        case .none: "없음"
        case .rain: "비"
        case .rainSnow: "비/눈"
        case .snow: "눈"
        case .shower: "소나기"
        }
    }
}

enum CongestionLevel: String, Codable, Sendable, Equatable, CaseIterable {
    case relaxed = "RELAXED"
    case normal = "NORMAL"
    case slightlyCrowded = "SLIGHTLY_CROWDED"
    case crowded = "CROWDED"

    var displayName: String {
        switch self {
        case .relaxed: "여유"
        case .normal: "보통"
        case .slightlyCrowded: "약간 붐빔"
        case .crowded: "붐빔"
        }
    }
}

struct EmptyResponse: Decodable, Sendable, Equatable {}

enum BookmarkError: Error, Sendable, Equatable {
    case alreadyBookmarked
}
