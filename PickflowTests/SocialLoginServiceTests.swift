import XCTest
@testable import Pickflow

/// PV-40 — 로그인 성공 시 검수완료 알림을 다시 확인하도록 신호를 보낸다.
final class SocialLoginServiceTests: XCTestCase {
    private var authService: MockAuthService!
    private var kakaoAuthProvider: MockKakaoAuthProvider!
    private var appleAuthProvider: MockAppleAuthProvider!
    private var tokenStore: MockTokenStore!
    private var service: SocialLoginService!

    override func setUp() {
        super.setUp()
        authService = MockAuthService()
        kakaoAuthProvider = MockKakaoAuthProvider()
        appleAuthProvider = MockAppleAuthProvider()
        tokenStore = MockTokenStore()
        service = SocialLoginService(
            authService: authService,
            kakaoAuthProvider: kakaoAuthProvider,
            appleAuthProvider: appleAuthProvider,
            tokenStore: tokenStore
        )
    }

    override func tearDown() {
        service = nil
        tokenStore = nil
        appleAuthProvider = nil
        kakaoAuthProvider = nil
        authService = nil
        super.tearDown()
    }

    func test_카카오_로그인_성공하면_검수확인_알림을_보낸다() async throws {
        var received: Notification.Name?
        let observer = NotificationCenter.default.addObserver(
            forName: .spotReviewCheckRequested, object: nil, queue: nil
        ) { received = $0.name }
        defer { NotificationCenter.default.removeObserver(observer) }

        try await service.signInWithKakao()

        XCTAssertEqual(received, .spotReviewCheckRequested)
    }

    func test_애플_로그인_성공하면_검수확인_알림을_보낸다() async throws {
        var received: Notification.Name?
        let observer = NotificationCenter.default.addObserver(
            forName: .spotReviewCheckRequested, object: nil, queue: nil
        ) { received = $0.name }
        defer { NotificationCenter.default.removeObserver(observer) }

        try await service.signInWithApple()

        XCTAssertEqual(received, .spotReviewCheckRequested)
    }

    func test_로그인_실패하면_알림을_보내지_않는다() async {
        authService.kakaoResult = .failure(TestError.failed)
        var received: Notification.Name?
        let observer = NotificationCenter.default.addObserver(
            forName: .spotReviewCheckRequested, object: nil, queue: nil
        ) { received = $0.name }
        defer { NotificationCenter.default.removeObserver(observer) }

        _ = try? await service.signInWithKakao()

        XCTAssertNil(received)
    }
}
