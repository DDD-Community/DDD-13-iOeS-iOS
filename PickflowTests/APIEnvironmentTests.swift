import XCTest
@testable import Pickflow

/// 서버 주소가 조용히 바뀌면 인증만 다른 서버로 나가는 사고가 나므로,
/// base URL 구성과 오버라이드 동작을 고정해둔다.
final class APIEnvironmentTests: XCTestCase {

    override func setUp() {
        super.setUp()
        APIEnvironment.clearOverride()
    }

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
        XCTAssertTrue(APIEnvironment.isOverridden)
        XCTAssertEqual(APIBaseURL.current, "https://pickflow-api.us/api")
    }

    func test_오버라이드를지우면_빌드기본값으로돌아간다() {
        APIEnvironment.setOverride(.prod)

        APIEnvironment.clearOverride()

        XCTAssertEqual(APIEnvironment.current, .buildDefault)
        XCTAssertFalse(APIEnvironment.isOverridden)
    }

    /// 핵심 안전장치 — 전환해둔 걸 잊은 유저가 업데이트 후에도 계속 dev 를 보면 안 된다.
    func test_앱버전이바뀌면_오버라이드가무시된다() {
        APIEnvironment.setOverride(.prod)
        XCTAssertEqual(APIEnvironment.current, .prod)

        // 이전 버전에서 전환해둔 상태를 흉내낸다.
        UserDefaults.standard.set("0.0.1-old", forKey: APIEnvironment.overrideAppVersionKey)

        XCTAssertEqual(APIEnvironment.current, .buildDefault)
        XCTAssertFalse(APIEnvironment.isOverridden)
    }

    func test_알수없는값이저장돼있으면_빌드기본값을쓴다() {
        UserDefaults.standard.set("staging", forKey: APIEnvironment.overrideKey)
        UserDefaults.standard.set(APIEnvironment.currentAppVersion, forKey: APIEnvironment.overrideAppVersionKey)

        XCTAssertEqual(APIEnvironment.current, .buildDefault)
    }

    /// 인증 엔드포인트가 별도 상수를 쓰던 시절의 회귀 방지.
    /// 모든 엔드포인트가 같은 호스트를 봐야 한다.
    func test_인증엔드포인트도_같은baseURL을쓴다() {
        APIEnvironment.setOverride(.prod)

        XCTAssertEqual(AuthEndpoint.refresh(refreshToken: "t").baseURL, APIBaseURL.current)
        XCTAssertEqual(SpotEndpoint.detail(spotId: 1).baseURL, APIBaseURL.current)
        XCTAssertEqual(APIBaseURL.current, "https://pickflow-api.us/api")
    }

    // MARK: - 실행 인자

    /// 개발 중에는 스킴에 `-apiEnvironment dev` 를 넣어두고 UI 를 아예 거치지 않는다.
    func test_실행인자가_저장된오버라이드보다우선한다() {
        APIEnvironment.setOverride(.prod)

        withLaunchArgument("dev") {
            XCTAssertEqual(APIEnvironment.current, .dev)
            XCTAssertTrue(APIEnvironment.isOverridden)
        }

        // 인자가 빠지면 저장된 값으로 되돌아간다.
        XCTAssertEqual(APIEnvironment.current, .prod)
    }

    func test_실행인자값이_알수없는문자열이면_무시된다() {
        withLaunchArgument("staging") {
            XCTAssertNil(APIEnvironment.launchArgumentOverride)
            XCTAssertEqual(APIEnvironment.current, .buildDefault)
        }
    }

    private func withLaunchArgument(_ value: String, _ body: () -> Void) {
        let defaults = UserDefaults.standard
        let original = defaults.volatileDomain(forName: UserDefaults.argumentDomain)
        var patched = original
        patched[APIEnvironment.launchArgumentKey] = value
        defaults.setVolatileDomain(patched, forName: UserDefaults.argumentDomain)
        defer { defaults.setVolatileDomain(original, forName: UserDefaults.argumentDomain) }
        body()
    }

    // MARK: - 숨은 진입점

    func test_잠금해제_규칙이_우연히열리지않을만큼이다() {
        XCTAssertGreaterThanOrEqual(APIEnvironmentUnlock.requiredTapCount, 5)
        XCTAssertFalse(APIEnvironmentUnlock.passcode.isEmpty)
    }
}
