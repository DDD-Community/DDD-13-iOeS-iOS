import XCTest
@testable import Pickflow

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    private var completionStore: MockOnboardingCompletionStore!
    private var viewModel: OnboardingViewModel!

    override func setUp() async throws {
        try await super.setUp()
        completionStore = MockOnboardingCompletionStore()
        viewModel = makeViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
        completionStore = nil
        try await super.tearDown()
    }

    // MARK: - 초기 상태

    func test_초기상태_currentIndex는0이고_isFinished는false이다() {
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertFalse(viewModel.isFinished)
    }

    func test_초기상태_기본페이지가4개이고_정의된순서를유지한다() {
        XCTAssertEqual(viewModel.pages.count, 4)
        XCTAssertEqual(viewModel.pages.map(\.id), [0, 1, 2, 3])
        XCTAssertEqual(viewModel.pages.map(\.imageName), [
            "onboarding_0", "onboarding_1", "onboarding_1", "onboarding_0"
        ])
    }

    func test_초기상태_모든페이지가orange테마이다() {
        let themes = viewModel.pages.map(\.theme)
        XCTAssertEqual(themes, [.orange, .orange, .orange, .orange])
    }

    func test_초기상태_isOnFirstPage는true이고_isOnLastPage는false이다() {
        XCTAssertTrue(viewModel.isOnFirstPage)
        XCTAssertFalse(viewModel.isOnLastPage)
    }

    // MARK: - goToNextPage

    func test_goToNextPage_중간페이지에서_currentIndex가1증가한다() {
        viewModel.goToNextPage()
        XCTAssertEqual(viewModel.currentIndex, 1)
        viewModel.goToNextPage()
        XCTAssertEqual(viewModel.currentIndex, 2)
    }

    func test_goToNextPage_마지막페이지에서_currentIndex가더이상증가하지않는다() {
        viewModel.setPage(3)
        viewModel.goToNextPage()
        XCTAssertEqual(viewModel.currentIndex, 3)
        XCTAssertTrue(viewModel.isOnLastPage)
    }

    // MARK: - goToPreviousPage

    func test_goToPreviousPage_중간페이지에서_currentIndex가1감소한다() {
        viewModel.setPage(2)
        viewModel.goToPreviousPage()
        XCTAssertEqual(viewModel.currentIndex, 1)
    }

    func test_goToPreviousPage_첫페이지에서_currentIndex가0미만으로내려가지않는다() {
        viewModel.goToPreviousPage()
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertTrue(viewModel.isOnFirstPage)
    }

    // MARK: - setPage

    func test_setPage_유효범위안값_그대로반영된다() {
        viewModel.setPage(2)
        XCTAssertEqual(viewModel.currentIndex, 2)
    }

    func test_setPage_음수_0으로clamp된다() {
        viewModel.setPage(-5)
        XCTAssertEqual(viewModel.currentIndex, 0)
    }

    func test_setPage_상한초과_마지막인덱스로clamp된다() {
        viewModel.setPage(99)
        XCTAssertEqual(viewModel.currentIndex, viewModel.pages.count - 1)
    }

    // MARK: - finishOnboarding

    func test_finishOnboarding_호출시_store에markOnboardingSeen이호출된다() {
        viewModel.finishOnboarding()
        XCTAssertEqual(completionStore.markCallCount, 1)
        XCTAssertTrue(completionStore.hasSeenValue)
    }

    func test_finishOnboarding_호출시_isFinished가true가된다() {
        XCTAssertFalse(viewModel.isFinished)
        viewModel.finishOnboarding()
        XCTAssertTrue(viewModel.isFinished)
    }

    func test_finishOnboarding_어느페이지에서호출해도_완료처리된다() {
        viewModel.setPage(1)
        viewModel.finishOnboarding()
        XCTAssertTrue(viewModel.isFinished)
        XCTAssertEqual(completionStore.markCallCount, 1)
    }

    // MARK: - primary CTA

    func test_primaryButtonTitle_마지막페이지전까지_다음으로이다() {
        XCTAssertEqual(viewModel.primaryButtonTitle, "다음으로")
        viewModel.setPage(2)
        XCTAssertEqual(viewModel.primaryButtonTitle, "다음으로")
    }

    func test_primaryButtonTitle_마지막페이지에서_시작하기이다() {
        viewModel.setPage(3)
        XCTAssertEqual(viewModel.primaryButtonTitle, "시작하기")
    }

    func test_primaryButtonTapped_마지막페이지전에는_다음페이지로이동하고완료하지않는다() {
        viewModel.primaryButtonTapped()

        XCTAssertEqual(viewModel.currentIndex, 1)
        XCTAssertFalse(viewModel.isFinished)
        XCTAssertEqual(completionStore.markCallCount, 0)
    }

    func test_primaryButtonTapped_마지막페이지에서는_온보딩을완료한다() {
        viewModel.setPage(3)
        viewModel.primaryButtonTapped()

        XCTAssertTrue(viewModel.isFinished)
        XCTAssertEqual(completionStore.markCallCount, 1)
    }

    // MARK: - isOnLastPage 위치 계산

    func test_isOnLastPage_마지막인덱스에서만true이다() {
        XCTAssertFalse(viewModel.isOnLastPage)
        viewModel.setPage(1)
        XCTAssertFalse(viewModel.isOnLastPage)
        viewModel.setPage(viewModel.pages.count - 1)
        XCTAssertTrue(viewModel.isOnLastPage)
    }

    // MARK: - Helpers

    private func makeViewModel(
        pages: [OnboardingPage] = OnboardingPage.defaultPages
    ) -> OnboardingViewModel {
        OnboardingViewModel(pages: pages, completionStore: completionStore)
    }
}
