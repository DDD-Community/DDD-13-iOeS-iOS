import Alamofire
import XCTest
@testable import Pickflow

/// 다중선택 필터의 서버 계약을 고정한다.
/// 서버는 반복 파라미터(`?theme=SUNSET&theme=YUNSEUL`)로 받는다 — BE PR #162.
final class SpotThemeQueryTests: XCTestCase {

    func test_선택이없으면_쿼리값이nil이다() {
        XCTAssertNil(SpotThemeQuery.values(for: []))
    }

    func test_단일선택시_해당apiCode하나를돌려준다() {
        XCTAssertEqual(SpotThemeQuery.values(for: [.sunset]), ["SUNSET"])
    }

    /// Set 은 순서가 없으므로 allCases(햇살/윤슬/노을/야경) 순으로 정규화돼야 한다.
    func test_Set순서와무관하게_allCases순서로정규화된다() {
        let values = SpotThemeQuery.values(for: [.nightView, .sunset, .reflection, .sunlight])

        XCTAssertEqual(values, ["SUNLIGHT", "YUNSEUL", "SUNSET", "NIGHT_VIEW"])
    }

    func test_apiCode는양방향으로매핑된다() {
        for theme in SpotTheme.allCases {
            XCTAssertEqual(SpotTheme(apiCode: theme.apiCode), theme)
        }
    }

    /// 서버 리스트 응답은 축약 코드로 내려온다. (SS=노을, YS=윤슬, SL=햇살, NV=야경)
    func test_축약코드도디코딩된다() {
        XCTAssertEqual(SpotTheme(apiCode: "SS"), .sunset)
        XCTAssertEqual(SpotTheme(apiCode: "YS"), .reflection)
        XCTAssertEqual(SpotTheme(apiCode: "SL"), .sunlight)
        XCTAssertEqual(SpotTheme(apiCode: "NV"), .nightView)
    }

    // MARK: - 실제 직렬화

    /// Alamofire 기본 인코딩은 배열을 `theme[]=` 로 만든다.
    /// 대괄호가 붙으면 서버가 필터를 인식하지 못하므로 실제 쿼리 문자열까지 확인한다.
    func test_리스트_다중선택이_반복파라미터로직렬화된다() throws {
        let endpoint = SpotListEndpoint(
            page: 0,
            themes: [.sunlight, .sunset],
            sort: nil,
            latitude: nil,
            longitude: nil,
            regionId: nil
        )

        let query = try encodedQuery(of: endpoint)

        XCTAssertTrue(query.contains("theme=SUNLIGHT"), query)
        XCTAssertTrue(query.contains("theme=SUNSET"), query)
        XCTAssertFalse(query.contains("theme%5B%5D"), "대괄호 배열 인코딩이면 서버가 못 읽는다: \(query)")
    }

    func test_지도_다중선택이_반복파라미터로직렬화된다() throws {
        let endpoint = SpotViewportEndpoint(viewport: .fixture(), themes: [.reflection, .nightView], regionId: nil)

        let query = try encodedQuery(of: endpoint)

        XCTAssertTrue(query.contains("theme=YUNSEUL"), query)
        XCTAssertTrue(query.contains("theme=NIGHT_VIEW"), query)
        XCTAssertFalse(query.contains("theme%5B%5D"), "대괄호 배열 인코딩이면 서버가 못 읽는다: \(query)")
    }

    func test_선택이없으면_theme파라미터가아예빠진다() throws {
        let endpoint = SpotListEndpoint(page: 0, themes: [], sort: nil, latitude: nil, longitude: nil, regionId: nil)

        let query = try encodedQuery(of: endpoint)

        XCTAssertFalse(query.contains("theme"), query)
    }

    private func encodedQuery(of endpoint: any APIEndpoint) throws -> String {
        let request = try endpoint.encoding.encode(
            URLRequest(url: XCTUnwrap(URL(string: endpoint.url))),
            with: endpoint.parameters
        )
        return request.url?.query ?? ""
    }
}
