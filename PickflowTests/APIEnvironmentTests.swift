import XCTest
@testable import Pickflow

/// 서버 주소가 조용히 바뀌면 인증만 다른 서버로 나가는 사고가 나므로,
/// base URL 구성과 오버라이드 동작을 고정해둔다.
final class APIEnvironmentTests: XCTestCase {

    override func tearDown() {
        APIEnvironment.clearOverride()
        super.tearDown()
    }

    func test_환경별_baseURL이_명세대로다() {
        XCTAssertEqual(APIEnvironment.dev.baseURL, "https://dev-api.pickflow-api.us/api")
        XCTAssertEqual(APIEnvironment.prod.baseURL, "https://pickflow-api.us/api")
    }

    /// 테스트는 Debug 빌드에서 돌므로 기본값이 dev 여야 한다.
    func test_Debug빌드_기본값은_dev다() {
        XCTAssertEqual(APIEnvironment.buildDefault, .dev)
    }

    func test_오버라이드하면_current가바뀐다() {
        APIEnvironment.setOverride(.prod)

        XCTAssertEqual(APIEnvironment.current, .prod)
        XCTAssertEqual(APIBaseURL.current, "https://pickflow-api.us/api")
    }

    func test_오버라이드를지우면_빌드기본값으로돌아간다() {
        APIEnvironment.setOverride(.prod)

        APIEnvironment.clearOverride()

        XCTAssertEqual(APIEnvironment.current, .buildDefault)
    }

    /// 인증 엔드포인트가 별도 상수를 쓰던 시절의 회귀 방지.
    /// 모든 엔드포인트가 같은 호스트를 봐야 한다.
    func test_인증엔드포인트도_같은baseURL을쓴다() {
        APIEnvironment.setOverride(.dev)

        XCTAssertEqual(AuthEndpoint.refresh(refreshToken: "t").baseURL, APIBaseURL.current)
        XCTAssertEqual(SpotEndpoint.detail(spotId: 1).baseURL, APIBaseURL.current)
        XCTAssertEqual(APIBaseURL.current, "https://dev-api.pickflow-api.us/api")
    }
}
