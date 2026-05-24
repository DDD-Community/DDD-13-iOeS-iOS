import Foundation

struct SpotDetailDTO: Decodable, Sendable {
    let spotId: Int64
    let name: String
    let comment: String
    let theme: String
    let latitude: Double
    let longitude: Double
    let address: String
    let imageUrl: String?
    let recordedDate: String?
    let recordedTime: String?
    let weatherSky: String?
    let precipitationProbability: Int?
    let congestionLevel: String?
    let sunsetTime: String?
    let parkingInfo: String?
    let bookmarkCount: Int
    let isBookmarked: Bool
    let isMySpot: Bool
}

extension SpotDetail {
    init(dto: SpotDetailDTO) {
        self.init(
            id: dto.spotId,
            name: dto.name,
            comment: dto.comment,
            theme: SpotTheme(detailApiCode: dto.theme) ?? .sunset,
            latitude: dto.latitude,
            longitude: dto.longitude,
            address: dto.address,
            imageUrl: dto.imageUrl,
            recordedTime: dto.recordedTime,
            isBookmarked: dto.isBookmarked,
            bookmarkCount: dto.bookmarkCount,
            isMySpot: dto.isMySpot,
            weather: SpotWeather(
                precipitationProbability: dto.precipitationProbability,
                condition: dto.weatherSky.flatMap(WeatherCondition.init(rawValue:)),
                sunsetTime: dto.sunsetTime,
                congestion: dto.congestionLevel.flatMap(Congestion.init(rawValue:)),
                parking: dto.parkingInfo
            )
        )
    }
}
