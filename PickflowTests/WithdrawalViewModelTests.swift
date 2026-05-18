import XCTest
@testable import Pickflow

@MainActor
final class WithdrawalViewModelTests: XCTestCase {
    private var userService: MockUserService!
    private var authService: MockAuthServiceForProfile!
    private var viewModel: WithdrawalViewModel!

    override func setUp() async throws {
        try await super.setUp()
        userService = MockUserService()
        authService = MockAuthServiceForProfile()
        viewModel = WithdrawalViewModel(userService: userService, authService: authService)
    }

    override func tearDown() async throws {
        viewModel = nil
        authService = nil
        userService = nil
        try await super.tearDown()
    }

    // MARK: - canSubmit

    func test_canSubmit_초기상태_false를반환한다() {
        XCTAssertFalse(viewModel.canSubmit)
    }

    func test_canSubmit_사유선택됨_동의미체크_false를반환한다() {
        viewModel.selectReason(.rarelyUsed)

        XCTAssertFalse(viewModel.canSubmit)
    }

    func test_canSubmit_동의체크됨_사유미선택_false를반환한다() {
        viewModel.toggleAgreement()

        XCTAssertFalse(viewModel.canSubmit)
    }

    func test_canSubmit_사유선택_동의체크_true를반환한다() {
        viewModel.selectReason(.rarelyUsed)
        viewModel.toggleAgreement()

        XCTAssertTrue(viewModel.canSubmit)
    }

    func test_canSubmit_기타선택_텍스트필드비어있음_false를반환한다() {
        viewModel.selectReason(.other)
        viewModel.toggleAgreement()
        viewModel.otherFeedback = ""

        XCTAssertFalse(viewModel.canSubmit)
    }

    func test_canSubmit_기타선택_공백만입력_false를반환한다() {
        viewModel.selectReason(.other)
        viewModel.toggleAgreement()
        viewModel.otherFeedback = "   "

        XCTAssertFalse(viewModel.canSubmit)
    }

    func test_canSubmit_기타선택_텍스트입력됨_동의체크_true를반환한다() {
        viewModel.selectReason(.other)
        viewModel.toggleAgreement()
        viewModel.otherFeedback = "개선 의견이에요"

        XCTAssertTrue(viewModel.canSubmit)
    }

    // MARK: - selectReason / toggleDropdown

    func test_selectReason_사유가설정되고드롭다운이닫힌다() {
        viewModel.toggleDropdown()
        XCTAssertTrue(viewModel.isDropdownOpen)

        viewModel.selectReason(.difficultToUse)

        XCTAssertEqual(viewModel.selectedReason, .difficultToUse)
        XCTAssertFalse(viewModel.isDropdownOpen)
    }

    func test_toggleDropdown_반복호출시열림닫힘반복된다() {
        XCTAssertFalse(viewModel.isDropdownOpen)
        viewModel.toggleDropdown()
        XCTAssertTrue(viewModel.isDropdownOpen)
        viewModel.toggleDropdown()
        XCTAssertFalse(viewModel.isDropdownOpen)
    }

    // MARK: - submitWithdrawal

    func test_submitWithdrawal_canSubmit이false인경우_API호출안함() async throws {
        // 사유 미선택 상태

        await viewModel.submitWithdrawal()

        XCTAssertEqual(userService.deleteCallCount, 0)
        XCTAssertEqual(viewModel.step, .input)
    }

    func test_submitWithdrawal_일반사유선택_성공_done으로전환되고signOut호출된다() async throws {
        viewModel.selectReason(.rarelyUsed)
        viewModel.toggleAgreement()

        await viewModel.submitWithdrawal()

        XCTAssertEqual(viewModel.step, .done)
        XCTAssertEqual(userService.deleteCallCount, 1)
        XCTAssertEqual(authService.signOutCallCount, 1)
    }

    func test_submitWithdrawal_기타선택_텍스트포함_otherFeedback이전달된다() async throws {
        viewModel.selectReason(.other)
        viewModel.toggleAgreement()
        viewModel.otherFeedback = "개선 의견이에요"

        await viewModel.submitWithdrawal()

        XCTAssertEqual(viewModel.step, .done)
        XCTAssertEqual(userService.deleteCallCount, 1)
    }

    func test_submitWithdrawal_API실패_step이failed로전환된다() async throws {
        userService.deleteError = TestError.failed
        viewModel.selectReason(.rarelyUsed)
        viewModel.toggleAgreement()

        await viewModel.submitWithdrawal()

        guard case .failed = viewModel.step else {
            return XCTFail("Expected .failed step")
        }
        XCTAssertEqual(authService.signOutCallCount, 0)
    }
}
