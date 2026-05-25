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

enum SpotTheme: String, Sendable, Equatable, CaseIterable {
    case sunset = "노을"
    case reflection = "윤슬"
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
    var apiCode: String {
        switch self {
        case .sunset: "SUNSET"
        case .reflection: "YUNSEUL"
        }
    }

    init?(apiCode: String) {
        switch apiCode {
        case "SUNSET", "SS": self = .sunset
        case "YUNSEUL", "YS": self = .reflection
        default: return nil
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

enum SpotReportType: String, Codable, Sendable {
    case locationError = "LOCATION_ERROR"
    case wrongName = "WRONG_NAME"
    case etc = "ETC"
}

struct EmptyResponse: Decodable, Sendable, Equatable {}

enum BookmarkError: Error, Sendable, Equatable {
    case alreadyBookmarked
}
