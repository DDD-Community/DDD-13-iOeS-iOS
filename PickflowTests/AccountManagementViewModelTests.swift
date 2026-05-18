import XCTest
@testable import Pickflow

@MainActor
final class AccountManagementViewModelTests: XCTestCase {
    private var userService: MockUserService!
    private var authService: MockAuthServiceForProfile!
    private var viewModel: AccountManagementViewModel!

    override func setUp() async throws {
        try await super.setUp()
        userService = MockUserService()
        authService = MockAuthServiceForProfile()
        viewModel = AccountManagementViewModel(userService: userService, authService: authService)
    }

    override func tearDown() async throws {
        viewModel = nil
        authService = nil
        userService = nil
        try await super.tearDown()
    }

    // MARK: - onAppear

    func test_onAppear_성공_유저정보와닉네임초안이채워진다() async throws {
        userService.fetchResult = .success(.fixture(nickname: "capybara123"))

        await viewModel.onAppear()

        XCTAssertEqual(viewModel.user, .fixture(nickname: "capybara123"))
        XCTAssertEqual(viewModel.nicknameDraft, "capybara123")
        XCTAssertNil(viewModel.loadError)
    }

    func test_onAppear_실패_loadError가설정된다() async throws {
        userService.fetchResult = .failure(TestError.failed)

        await viewModel.onAppear()

        XCTAssertNil(viewModel.user)
        XCTAssertNotNil(viewModel.loadError)
    }

    // MARK: - isSaveEnabled

    func test_isSaveEnabled_닉네임미변경_false를반환한다() async throws {
        userService.fetchResult = .success(.fixture(nickname: "capybara123"))
        await viewModel.onAppear()

        viewModel.nicknameDraft = "capybara123"

        XCTAssertFalse(viewModel.isSaveEnabled)
    }

    func test_isSaveEnabled_닉네임변경됨_true를반환한다() async throws {
        userService.fetchResult = .success(.fixture(nickname: "capybara123"))
        await viewModel.onAppear()

        viewModel.nicknameDraft = "newname"

        XCTAssertTrue(viewModel.isSaveEnabled)
    }

    func test_isSaveEnabled_닉네임공백만입력_false를반환한다() async throws {
        userService.fetchResult = .success(.fixture(nickname: "capybara123"))
        await viewModel.onAppear()

        viewModel.nicknameDraft = "   "

        XCTAssertFalse(viewModel.isSaveEnabled)
    }

    // MARK: - saveProfile

    func test_saveProfile_성공_saveState가saved로전환되고유저가갱신된다() async throws {
        userService.fetchResult = .success(.fixture(nickname: "capybara123"))
        userService.updateResult = .success(.fixture(nickname: "newname"))
        await viewModel.onAppear()
        viewModel.nicknameDraft = "newname"

        await viewModel.saveProfile()

        XCTAssertEqual(viewModel.saveState, .saved)
        XCTAssertEqual(viewModel.user?.nickname, "newname")
        XCTAssertEqual(userService.updateCalls.first?.nickname, "newname")
    }

    func test_saveProfile_실패_saveState가failed로전환된다() async throws {
        userService.fetchResult = .success(.fixture(nickname: "capybara123"))
        userService.updateResult = .failure(TestError.failed)
        await viewModel.onAppear()
        viewModel.nicknameDraft = "newname"

        await viewModel.saveProfile()

        guard case .failed = viewModel.saveState else {
            return XCTFail("Expected .failed state")
        }
    }

    func test_saveProfile_isSaveEnabled가false인경우_API호출안함() async throws {
        userService.fetchResult = .success(.fixture(nickname: "capybara123"))
        await viewModel.onAppear()
        // nicknameDraft == user.nickname → isSaveEnabled false

        await viewModel.saveProfile()

        XCTAssertTrue(userService.updateCalls.isEmpty)
    }

    // MARK: - Logout flow

    func test_requestLogout_logoutState가confirming으로전환된다() {
        viewModel.requestLogout()

        XCTAssertEqual(viewModel.logoutState, .confirming)
    }

    func test_cancelLogout_logoutState가idle로전환된다() {
        viewModel.requestLogout()
        viewModel.cancelLogout()

        XCTAssertEqual(viewModel.logoutState, .idle)
    }

    func test_confirmLogout_성공_logoutState가done으로전환된다() async throws {
        viewModel.requestLogout()

        await viewModel.confirmLogout()

        XCTAssertEqual(viewModel.logoutState, .done)
        XCTAssertEqual(authService.signOutCallCount, 1)
    }

    func test_confirmLogout_실패_logoutState가failed로전환된다() async throws {
        authService.signOutError = TestError.failed
        viewModel.requestLogout()

        await viewModel.confirmLogout()

        guard case .failed = viewModel.logoutState else {
            return XCTFail("Expected .failed state")
        }
    }
}
