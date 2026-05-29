import Foundation

/// 뷰포트 영역 안의 스팟 element. 큐레이션/내 스팟 모두 동일 모델로 표현되며 `isMySpot` 으로 구분된다.
struct SpotSummary: Codable, Sendable, Identifiable, Equatable {
    let spotId: Int64
    let spotImageUrl: String
    let latitude: Double
    let longitude: Double
    let isMySpot: Bool

    var id: Int64 { spotId }
    var coordinate: Coordinate { Coordinate(latitude: latitude, longitude: longitude) }
}

struct SpotViewportResponse: Codable, Sendable, Equatable {
    let spots: [SpotSummary]
}
