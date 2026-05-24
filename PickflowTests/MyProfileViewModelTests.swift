import XCTest
@testable import Pickflow

@MainActor
final class MyProfileViewModelTests: XCTestCase {
    private var userService: MockUserService!
    private var authService: MockAuthServiceForProfile!
    private var viewModel: MyProfileViewModel!

    override func setUp() async throws {
        try await super.setUp()
        userService = MockUserService()
        authService = MockAuthServiceForProfile()
        viewModel = MyProfileViewModel(userService: userService, authService: authService, socialLoginService: MockSocialLoginServiceForProfile())
    }

    override func tearDown() async throws {
        viewModel = nil
        authService = nil
        userService = nil
        try await super.tearDown()
    }

    // MARK: - onAppear

    func test_onAppear_비로그인상태_상태가signedOut으로전환된다() async throws {
        authService.stubbedAuthState = .signedOut

        await viewModel.onAppear()

        XCTAssertEqual(viewModel.state, .signedOut)
        XCTAssertEqual(userService.fetchCallCount, 0)
    }

    func test_onAppear_로그인상태_유저정보로드성공_상태가signedIn으로전환된다() async throws {
        authService.stubbedAuthState = .signedIn(AuthToken(accessToken: "a", refreshToken: "r"))
        userService.fetchResult = .success(.fixture(nickname: "testuser"))

        await viewModel.onAppear()

        XCTAssertEqual(viewModel.state, .signedIn(.fixture(nickname: "testuser")))
        XCTAssertEqual(userService.fetchCallCount, 1)
    }

    func test_onAppear_로그인상태_유저정보로드실패_상태가failed로전환된다() async throws {
        authService.stubbedAuthState = .signedIn(AuthToken(accessToken: "a", refreshToken: "r"))
        userService.fetchResult = .failure(TestError.failed)

        await viewModel.onAppear()

        guard case let .failed(message) = viewModel.state else {
            return XCTFail("Expected .failed state")
        }
        XCTAssertTrue(message.contains("test failure"))
    }

    // MARK: - refresh

    func test_refresh_성공_기존상태에서_새유저데이터로갱신된다() async throws {
        userService.fetchResult = .success(.fixture(nickname: "refreshed"))

        await viewModel.refresh()

        XCTAssertEqual(viewModel.state, .signedIn(.fixture(nickname: "refreshed")))
    }
}
