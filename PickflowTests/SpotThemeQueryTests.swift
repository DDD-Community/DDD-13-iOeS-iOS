import XCTest
@testable import Pickflow

/// 다중선택 필터의 서버 쿼리 표현을 고정한다.
/// 서버 형식이 확정되면 이 테스트의 기대값과 `SpotThemeQuery` 만 함께 바뀐다.
final class SpotThemeQueryTests: XCTestCase {
    func test_선택이없으면_쿼리값이nil이다() {
        XCTAssertNil(SpotThemeQuery.value(for: []))
    }

    func test_단일선택시_해당apiCode를돌려준다() {
        XCTAssertEqual(SpotThemeQuery.value(for: [.sunset]), "SUNSET")
    }

    func test_다중선택시_콤마로join한다() {
        XCTAssertEqual(SpotThemeQuery.value(for: [.sunlight, .sunset]), "SUNLIGHT,SUNSET")
    }

    /// Set 은 순서가 없으므로 allCases(햇살/윤슬/노을/야경) 순으로 정규화돼야 한다.
    func test_Set순서와무관하게_allCases순서로정규화된다() {
        let value = SpotThemeQuery.value(for: [.nightView, .sunset, .reflection, .sunlight])

        XCTAssertEqual(value, "SUNLIGHT,YUNSEUL,SUNSET,NIGHT_VIEW")
    }

    func test_apiCode는양방향으로매핑된다() {
        for theme in SpotTheme.allCases {
            XCTAssertEqual(SpotTheme(apiCode: theme.apiCode), theme)
        }
    }
}
