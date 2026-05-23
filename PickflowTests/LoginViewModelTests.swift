import XCTest
@testable import Pickflow

@MainActor
final class LoginViewModelTests: XCTestCase {
    private var authService: MockAuthService!
    private var kakaoAuthProvider: MockKakaoAuthProvider!
    private var appleAuthProvider: MockAppleAuthProvider!
    private var tokenStore: MockTokenStore!
    private var viewModel: LoginViewModel!

    override func setUp() async throws {
        try await super.setUp()
        authService = MockAuthService()
        kakaoAuthProvider = MockKakaoAuthProvider()
        appleAuthProvider = MockAppleAuthProvider()
        tokenStore = MockTokenStore()
        viewModel = makeViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
        tokenStore = nil
        appleAuthProvider = nil
        kakaoAuthProvider = nil
        authService = nil
        try await super.tearDown()
    }

    func test_signInWithKakaoTapped_성공시_토큰을저장하고성공상태가된다() async throws {
        await viewModel.signInWithKakaoTapped()

        XCTAssertEqual(kakaoAuthProvider.callCount, 1)
        XCTAssertEqual(authService.kakaoAccessTokens, ["kakao-access-token"])
        XCTAssertEqual(tokenStore.savedTokens.first?.accessToken, "access-token")
        XCTAssertEqual(tokenStore.savedTokens.first?.refreshToken, "refresh-token")
        XCTAssertTrue(viewModel.didSignInSucceed)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_signInWithKakaoTapped_Provider실패시_에러메시지가설정되고백엔드를호출하지않는다() async throws {
        kakaoAuthProvider.result = .failure(TestError.failed)

        await viewModel.signInWithKakaoTapped()

        XCTAssertEqual(kakaoAuthProvider.callCount, 1)
        XCTAssertTrue(authService.kakaoAccessTokens.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "test failure")
        XCTAssertFalse(viewModel.didSignInSucceed)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_signInWithAppleTapped_성공시_자격증명으로로그인하고토큰을저장한다() async throws {
        await viewModel.signInWithAppleTapped()

        XCTAssertEqual(appleAuthProvider.callCount, 1)
        XCTAssertEqual(authService.appleRequests.first?.identityToken, "apple-identity-token")
        XCTAssertEqual(authService.appleRequests.first?.nonce, "raw-nonce")
        XCTAssertEqual(tokenStore.savedTokens.first?.accessToken, "apple-access-token")
        XCTAssertEqual(tokenStore.savedTokens.first?.refreshToken, "apple-refresh-token")
        XCTAssertTrue(viewModel.didSignInSucceed)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_signInWithAppleTapped_취소시_취소메시지가설정되고백엔드를호출하지않는다() async throws {
        appleAuthProvider.result = .failure(AppleAuthError.cancelled)

        await viewModel.signInWithAppleTapped()

        XCTAssertEqual(appleAuthProvider.callCount, 1)
        XCTAssertTrue(authService.appleRequests.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Apple 로그인이 취소되었어요.")
        XCTAssertFalse(viewModel.didSignInSucceed)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_signInWithAppleTapped_백엔드실패시_에러메시지가설정되고토큰을저장하지않는다() async throws {
        authService.appleResult = .failure(AuthError.validation)

        await viewModel.signInWithAppleTapped()

        XCTAssertEqual(appleAuthProvider.callCount, 1)
        XCTAssertEqual(authService.appleRequests.count, 1)
        XCTAssertTrue(tokenStore.savedTokens.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "입력값을 확인해 주세요.")
        XCTAssertFalse(viewModel.didSignInSucceed)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_continueAsGuestTapped_호출시_비회원진입요청상태가된다() {
        viewModel.continueAsGuestTapped()

        XCTAssertTrue(viewModel.didRequestGuestEntry)
    }

    private func makeViewModel() -> LoginViewModel {
        LoginViewModel(socialLoginService: MockSocialLoginService())
    }
}
