import Foundation

struct SpotDetail: Codable, Sendable, Identifiable, Equatable {
    let id: Int64
    let name: String
    let comment: String
    let theme: SpotTheme
    let latitude: Double
    let longitude: Double
    let distance: Double?
    let address: String
    let images: [SpotImage]
    let isBookmarked: Bool
    let weather: SpotWeather

    var primaryImage: SpotImage? {
        images.sorted { $0.displayOrder < $1.displayOrder }.first
    }
}

struct SpotImage: Codable, Sendable, Equatable {
    let imageURL: String
    let displayOrder: Int
    let recordedTime: String
}

struct SpotWeather: Codable, Sendable, Equatable {
    let temperature: Int
    let precipitationProbability: Int
    let condition: WeatherCondition
    let sunsetTime: String
    let congestion: Congestion
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

struct EmptyResponse: Decodable, Sendable, Equatable {}

enum BookmarkError: Error, Sendable, Equatable {
    case alreadyBookmarked
}
