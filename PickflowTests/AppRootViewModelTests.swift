import XCTest
@testable import Pickflow

@MainActor
final class AppRootViewModelTests: XCTestCase {
    private var authService: MockAuthService!
    private var onboardingStore: MockOnboardingCompletionStore!
    private var guestModeStore: MockGuestModeStore!
    private var viewModel: AppRootViewModel!

    override func setUp() async throws {
        try await super.setUp()
        authService = MockAuthService()
        onboardingStore = MockOnboardingCompletionStore()
        guestModeStore = MockGuestModeStore()
        viewModel = AppRootViewModel(
            authService: authService,
            socialLoginService: MockSocialLoginService(),
            locationService: MockLocationService(),
            onboardingCompletionStore: onboardingStore,
            guestModeStore: guestModeStore
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        guestModeStore = nil
        onboardingStore = nil
        authService = nil
        try await super.tearDown()
    }

    func test_bootstrap_회원이어도_온보딩이력이없으면_온보딩으로진입한다() async {
        authService.stubbedAuthState = .signedIn(
            AuthToken(accessToken: "access", refreshToken: "refresh")
        )

        await viewModel.bootstrap()

        XCTAssertEqual(viewModel.routeState, .onboarding)
    }

    func test_bootstrap_온보딩을본회원이면_메인으로진입한다() async {
        onboardingStore.hasSeenValue = true
        authService.stubbedAuthState = .signedIn(
            AuthToken(accessToken: "access", refreshToken: "refresh")
        )

        await viewModel.bootstrap()

        XCTAssertEqual(viewModel.routeState, .main)
    }

    func test_bootstrap_최초비회원이면_온보딩으로진입한다() async {
        await viewModel.bootstrap()

        XCTAssertEqual(viewModel.routeState, .onboarding)
    }

    func test_bootstrap_온보딩을본비회원이고게스트이력이없으면_로그인으로진입한다() async {
        onboardingStore.hasSeenValue = true

        await viewModel.bootstrap()

        XCTAssertEqual(viewModel.routeState, .signedOut)
    }

    func test_bootstrap_온보딩을본비회원이고게스트이력이있으면_메인으로진입한다() async {
        onboardingStore.hasSeenValue = true
        guestModeStore.hasEnteredValue = true

        await viewModel.bootstrap()

        XCTAssertEqual(viewModel.routeState, .main)
    }

    func test_didEnterGuest_게스트이력을저장하고메인으로진입한다() {
        viewModel.didEnterGuest()

        XCTAssertEqual(guestModeStore.markCallCount, 1)
        XCTAssertEqual(viewModel.routeState, .main)
    }
}
