import XCTest
@testable import Pickflow

final class RegionTests: XCTestCase {
    // MARK: - 디코딩 (서버 실제 필드명: regionId/regionName)

    func test_regionListResponse_서버필드명으로디코딩된다() throws {
        let json = """
        { "regions": [{ "regionId": 1, "regionName": "대전" }] }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(RegionListResponse.self, from: json)

        XCTAssertEqual(decoded.regions, [Region(id: 1, name: "대전")])
    }

    // MARK: - cameraBounds

    func test_cameraBounds_알려진지역명이면_bounds를반환한다() {
        XCTAssertNotNil(Region(id: 1, name: "대전").cameraBounds)
        XCTAssertNotNil(Region(id: 2, name: "서울").cameraBounds)
    }

    func test_cameraBounds_모르는지역명이면_nil이다() {
        XCTAssertNil(Region(id: 99, name: "부산").cameraBounds)
    }
}
