import Foundation

/// 탐색 화면 상단 지역 필터(대전/서울)의 단위. 스팟마다 부여된 regionId 기준으로 서버가 필터링한다.
/// 서버(`GET /v1/regions`)는 id/name만 내려주고 좌표는 주지 않는다 — 지도 카메라 자동 이동용
/// bounds는 `cameraBounds`에서 지역명 기준으로 별도 보유한다.
struct Region: Codable, Sendable, Identifiable, Equatable {
    let id: Int
    let name: String

    private enum CodingKeys: String, CodingKey {
        case id = "regionId"
        case name = "regionName"
    }
}

/// `GET /v1/regions` 응답 바디.
struct RegionListResponse: Codable, Sendable {
    let regions: [Region]
}

extension Region {
    /// 지역 선택 시 지도 카메라를 그 지역 전체가 보이게 자동 이동·줌하기 위한 남서/북동 경계.
    /// 서버가 좌표를 안 주므로 알려진 지역만 하드코딩 보유 — 목록에 없는(향후 확장) 지역이면 `nil`이라
    /// 필터링은 정상 동작하되 카메라 자동 이동만 생략된다.
    var cameraBounds: (southWest: Coordinate, northEast: Coordinate)? {
        Self.knownBounds[name]
    }

    private static let knownBounds: [String: (southWest: Coordinate, northEast: Coordinate)] = [
        "대전": (
            Coordinate(latitude: 36.198, longitude: 127.278),
            Coordinate(latitude: 36.489, longitude: 127.505)
        ),
        "서울": (
            Coordinate(latitude: 37.413, longitude: 126.764),
            Coordinate(latitude: 37.715, longitude: 127.184)
        ),
    ]

    /// 활성지역 조회 API 실패 시 폴백. 대전이 기본값으로 먼저 노출되어야 한다.
    static let fallbackRegions: [Region] = [
        Region(id: 1, name: "대전"),
        Region(id: 2, name: "서울"),
    ]
}
