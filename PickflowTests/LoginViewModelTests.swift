import XCTest
@testable import Pickflow

@MainActor
final class LoginViewModelTests: XCTestCase {
    private var socialLoginService: MockSocialLoginService!
    private var viewModel: LoginViewModel!

    override func setUp() async throws {
        try await super.setUp()
        socialLoginService = MockSocialLoginService()
        viewModel = makeViewModel()
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
        socialLoginService.kakaoError = TestError.failed

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

    func test_signInWithAppleTapped_실패시_에러메시지가설정된다() async throws {
        socialLoginService.appleError = TestError.failed

        await viewModel.signInWithAppleTapped()

        XCTAssertEqual(socialLoginService.appleCallCount, 1)
        XCTAssertFalse(viewModel.didSignInSucceed)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_continueAsGuestTapped_호출시_비회원진입요청상태가된다() {
        viewModel.continueAsGuestTapped()

        XCTAssertTrue(viewModel.didRequestGuestEntry)
    }

    private func makeViewModel() -> LoginViewModel {
        LoginViewModel(socialLoginService: socialLoginService)
    }
}
