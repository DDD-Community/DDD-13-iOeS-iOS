import XCTest
@testable import Pickflow

@MainActor
final class LoginViewModelTests: XCTestCase {
    private var socialLoginService: MockSocialLoginService!
    private var viewModel: LoginViewModel!

    override func setUp() async throws {
        try await super.setUp()
        socialLoginService = MockSocialLoginService()
        viewModel = LoginViewModel(socialLoginService: socialLoginService)
    }

    override func tearDown() async throws {
        viewModel = nil
        socialLoginService = nil
        try await super.tearDown()
    }

    func test_signInWithKakaoTapped_성공시_성공상태가된다() async throws {
        await viewModel.signInWithKakaoTapped()

        XCTAssertEqual(socialLoginService.kakaoCallCount, 1)
        XCTAssertTrue(viewModel.didSignInSucceed)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_signInWithKakaoTapped_실패시_에러메시지가설정된다() async throws {
        socialLoginService.kakaoResult = .failure(TestError.failed)

        await viewModel.signInWithKakaoTapped()

        XCTAssertEqual(socialLoginService.kakaoCallCount, 1)
        XCTAssertEqual(viewModel.errorMessage, "test failure")
        XCTAssertFalse(viewModel.didSignInSucceed)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_signInWithAppleTapped_성공시_성공상태가된다() async throws {
        await viewModel.signInWithAppleTapped()

        XCTAssertEqual(socialLoginService.appleCallCount, 1)
        XCTAssertTrue(viewModel.didSignInSucceed)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_signInWithAppleTapped_취소시_취소메시지가설정된다() async throws {
        socialLoginService.appleResult = .failure(AppleAuthError.cancelled)

        await viewModel.signInWithAppleTapped()

        XCTAssertEqual(socialLoginService.appleCallCount, 1)
        XCTAssertEqual(viewModel.errorMessage, "Apple 로그인이 취소되었어요.")
        XCTAssertFalse(viewModel.didSignInSucceed)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_signInWithAppleTapped_백엔드실패시_에러메시지가설정된다() async throws {
        socialLoginService.appleResult = .failure(AuthError.validation)

        await viewModel.signInWithAppleTapped()

        XCTAssertEqual(socialLoginService.appleCallCount, 1)
        XCTAssertEqual(viewModel.errorMessage, "입력값을 확인해 주세요.")
        XCTAssertFalse(viewModel.didSignInSucceed)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_continueAsGuestTapped_호출시_비회원진입요청상태가된다() {
        viewModel.continueAsGuestTapped()

        XCTAssertTrue(viewModel.didRequestGuestEntry)
    }
}
