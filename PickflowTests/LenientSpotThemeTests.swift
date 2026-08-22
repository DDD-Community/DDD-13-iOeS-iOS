import XCTest
@testable import Pickflow

/// 서버가 카테고리를 추가하면 앱 배포 전까지 그 코드를 해석할 수 없다.
/// 그때 스팟 하나 때문에 목록 전체가 날아가지 않아야 한다.
final class LenientSpotThemeTests: XCTestCase {

    func test_아는코드는_그대로해석된다() throws {
        let item = try decodeListItem(themeJSON: "\"SUNSET\"")
        XCTAssertEqual(item.theme, .sunset)
    }

    func test_축약코드도_해석된다() throws {
        let item = try decodeListItem(themeJSON: "\"NV\"")
        XCTAssertEqual(item.theme, .nightView)
    }

    func test_모르는코드는_nil이되고_디코딩은성공한다() throws {
        let item = try decodeListItem(themeJSON: "\"FOG\"")
        XCTAssertNil(item.theme)
        XCTAssertEqual(item.name, "테스트 스팟")
    }

    func test_null이어도_디코딩은성공한다() throws {
        let item = try decodeListItem(themeJSON: "null")
        XCTAssertNil(item.theme)
    }

    /// 핵심 회귀 방지 — 한 건이 해석 불가여도 나머지가 살아야 한다.
    func test_모르는코드가섞여도_나머지항목은살아남는다() throws {
        let json = Data("""
        {
          "spots": [
            { "spotId": 1, "name": "노을", "theme": "SUNSET", "thumbnailUrl": null, "distanceKm": 1.0, "isBookmarked": false },
            { "spotId": 2, "name": "미지", "theme": "FOG",    "thumbnailUrl": null, "distanceKm": 2.0, "isBookmarked": false },
            { "spotId": 3, "name": "야경", "theme": "NV",     "thumbnailUrl": null, "distanceKm": 3.0, "isBookmarked": false }
          ],
          "page": 0,
          "hasNext": false
        }
        """.utf8)

        let page = try JSONDecoder.pickflow.decode(SpotListPage.self, from: json)

        XCTAssertEqual(page.spots.count, 3)
        XCTAssertEqual(page.spots.map(\.theme), [.sunset, nil, .nightView])
    }

    /// unknown 이 enum 케이스가 아니므로 칩·필터·정렬에 새어들지 않는다.
    func test_allCases는_실제카테고리4개뿐이다() {
        XCTAssertEqual(SpotTheme.allCases, [.sunlight, .reflection, .sunset, .nightView])
    }

    private func decodeListItem(themeJSON: String) throws -> SpotListItem {
        let json = Data("""
        {
          "spotId": 1,
          "name": "테스트 스팟",
          "theme": \(themeJSON),
          "thumbnailUrl": null,
          "distanceKm": 1.2,
          "isBookmarked": false
        }
        """.utf8)
        return try JSONDecoder.pickflow.decode(SpotListItem.self, from: json)
    }
}
