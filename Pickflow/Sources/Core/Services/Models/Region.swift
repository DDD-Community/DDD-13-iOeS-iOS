import Foundation

/// 탐색 화면 상단 지역 필터(대전/서울)의 단위. 스팟마다 부여된 regionId 기준으로 서버가 필터링한다.
/// bounds는 지역 선택 시 지도 카메라를 그 지역으로 자동 이동·줌하는 데 쓰인다.
struct Region: Codable, Sendable, Identifiable, Equatable {
    let id: Int
    let name: String
    let southWestLatitude: Double
    let southWestLongitude: Double
    let northEastLatitude: Double
    let northEastLongitude: Double

    var southWest: Coordinate { Coordinate(latitude: southWestLatitude, longitude: southWestLongitude) }
    var northEast: Coordinate { Coordinate(latitude: northEastLatitude, longitude: northEastLongitude) }
}

extension Region {
    /// 활성지역 조회 API(BE 확정 전) 실패·미연동 시 폴백. 대전이 기본값으로 먼저 노출되어야 한다.
    /// bounds는 각 도시의 대략적인 행정구역 경계.
    static let fallbackRegions: [Region] = [
        Region(
            id: 1,
            name: "대전",
            southWestLatitude: 36.198,
            southWestLongitude: 127.278,
            northEastLatitude: 36.489,
            northEastLongitude: 127.505
        ),
        Region(
            id: 2,
            name: "서울",
            southWestLatitude: 37.413,
            southWestLongitude: 126.764,
            northEastLatitude: 37.715,
            northEastLongitude: 127.184
        ),
    ]
}
