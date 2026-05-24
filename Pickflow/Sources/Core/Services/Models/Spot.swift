import Foundation

struct SpotDetail: Codable, Sendable, Identifiable, Equatable {
    let id: Int64
    let name: String
    let comment: String
    let theme: SpotTheme
    let latitude: Double
    let longitude: Double
    let address: String
    let imageUrl: String?
    let recordedTime: String?
    let isBookmarked: Bool
    let bookmarkCount: Int
    let isMySpot: Bool
    let weather: SpotWeather

    var primaryImage: SpotImage? {
        guard let imageUrl else { return nil }
        return SpotImage(imageURL: imageUrl, displayOrder: 0, recordedTime: recordedTime ?? "")
    }
}

struct SpotImage: Codable, Sendable, Equatable {
    let imageURL: String
    let displayOrder: Int
    let recordedTime: String
}

struct SpotWeather: Codable, Sendable, Equatable {
    let precipitationProbability: Int?
    let condition: WeatherCondition?
    let sunsetTime: String?
    let congestion: Congestion?
    let parking: String?
}

enum SpotTheme: String, Codable, Sendable, Equatable {
    case sunset = "노을"
    case reflection = "윤슬"
}

enum WeatherCondition: String, Codable, Sendable, Equatable {
    case clear = "맑음"
    case cloudy = "구름 많음"
    case overcast = "흐림"
    case rain = "비"
    case rainSnow = "비/눈"
    case snow = "눈"
    case shower = "소나기"
}

enum Congestion: String, Codable, Sendable, Equatable {
    case relaxed = "여유"
    case normal = "보통"
    case slightlyCrowded = "약간 붐빔"
    case crowded = "붐빔"
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
