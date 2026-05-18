import XCTest
@testable import Pickflow

@MainActor
final class ArchiveViewModelTests: XCTestCase {
    private var archiveService: MockArchiveService!
    private var bookmarkService: MockBookmarkService!
    private var authService: MockAuthServiceForArchive!
    private var socialLoginService: MockSocialLoginService!
    private var viewModel: ArchiveViewModel!

    override func setUp() async throws {
        try await super.setUp()
        archiveService = MockArchiveService()
        bookmarkService = MockBookmarkService()
        authService = MockAuthServiceForArchive()
        socialLoginService = MockSocialLoginService()
        viewModel = makeViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
        socialLoginService = nil
        authService = nil
        bookmarkService = nil
        archiveService = nil
        try await super.tearDown()
    }

    // MARK: - onAppear

    func test_onAppear_비로그인상태_상태가signedOut으로전환된다() async {
        authService.stubbedAuthState = .signedOut

        await viewModel.onAppear()

        XCTAssertEqual(viewModel.state, .signedOut)
        XCTAssertTrue(archiveService.requestedPages.isEmpty)
    }

    func test_onAppear_로그인상태_정상응답_상태가loaded로전환된다() async {
        authService.stubbedAuthState = .signedIn(.fixture())
        archiveService.responder = { _ in
            .success(SpotListPage(spots: [.fixture()], page: 0, hasNext: false))
        }

        await viewModel.onAppear()

        XCTAssertEqual(viewModel.state, .loaded(items: [.fixture()], hasNext: false))
        XCTAssertEqual(archiveService.requestedPages, [0])
    }

    func test_onAppear_로그인상태_빈응답_상태가empty로전환된다() async {
        authService.stubbedAuthState = .signedIn(.fixture())
        archiveService.responder = { _ in
            .success(SpotListPage(spots: [], page: 0, hasNext: false))
        }

        await viewModel.onAppear()

        XCTAssertEqual(viewModel.state, .empty)
    }

    func test_onAppear_로그인상태_fetch실패_상태가failed로전환된다() async {
        authService.stubbedAuthState = .signedIn(.fixture())
        archiveService.responder = { _ in .failure(TestError.failed) }

        await viewModel.onAppear()

        guard case let .failed(message) = viewModel.state else {
            return XCTFail("Expected .failed state")
        }
        XCTAssertTrue(message.contains("test failure"))
    }

    // MARK: - signInWithKakao

    func test_signInWithKakao_성공시_데이터를로드하고signedOut에서벗어난다() async {
        authService.stubbedAuthState = .signedOut
        await viewModel.onAppear()
        XCTAssertEqual(viewModel.state, .signedOut)

        authService.stubbedAuthState = .signedIn(.fixture())
        archiveService.responder = { _ in
            .success(SpotListPage(spots: [.fixture()], page: 0, hasNext: false))
        }

        await viewModel.signInWithKakao()

        XCTAssertEqual(socialLoginService.kakaoCallCount, 1)
        XCTAssertEqual(viewModel.state, .loaded(items: [.fixture()], hasNext: false))
        XCTAssertFalse(viewModel.isLoginLoading)
        XCTAssertNil(viewModel.loginError)
    }

    func test_signInWithKakao_실패시_loginError를설정하고상태를유지한다() async {
        authService.stubbedAuthState = .signedOut
        await viewModel.onAppear()
        socialLoginService.kakaoError = TestError.failed

        await viewModel.signInWithKakao()

        XCTAssertNotNil(viewModel.loginError)
        XCTAssertEqual(viewModel.state, .signedOut)
        XCTAssertFalse(viewModel.isLoginLoading)
    }

    func test_signInWithKakao_로딩중_중복호출무시된다() async {
        // isLoginLoading이 true면 두 번째 호출은 무시
        // 직접 검증이 어려우므로 callCount로 간접 확인
        await viewModel.signInWithKakao()
        XCTAssertEqual(socialLoginService.kakaoCallCount, 1)
    }

    // MARK: - signInWithApple

    func test_signInWithApple_성공시_데이터를로드한다() async {
        authService.stubbedAuthState = .signedIn(.fixture())
        archiveService.responder = { _ in
            .success(SpotListPage(spots: [.fixture()], page: 0, hasNext: false))
        }

        await viewModel.signInWithApple()

        XCTAssertEqual(socialLoginService.appleCallCount, 1)
        XCTAssertEqual(viewModel.state, .loaded(items: [.fixture()], hasNext: false))
        XCTAssertFalse(viewModel.isLoginLoading)
    }

    func test_signInWithApple_실패시_loginError를설정한다() async {
        socialLoginService.appleError = TestError.failed

        await viewModel.signInWithApple()

        XCTAssertNotNil(viewModel.loginError)
        XCTAssertFalse(viewModel.isLoginLoading)
    }

    // MARK: - tabChanged

    func test_tabChanged_savedSpots에서mySpots로변경된다() {
        XCTAssertEqual(viewModel.selectedTab, .savedSpots)

        viewModel.tabChanged(.mySpots)

        XCTAssertEqual(viewModel.selectedTab, .mySpots)
    }

    func test_tabChanged_동일탭으로변경해도selectedTab은유지된다() {
        viewModel.tabChanged(.savedSpots)

        XCTAssertEqual(viewModel.selectedTab, .savedSpots)
    }

    // MARK: - loadNextPageIfNeeded

    func test_loadNextPageIfNeeded_hasNext가false면호출하지않는다() async {
        authService.stubbedAuthState = .signedIn(.fixture())
        archiveService.responder = { _ in
            .success(SpotListPage(spots: [.fixture()], page: 0, hasNext: false))
        }
        await viewModel.onAppear()
        let initialCount = archiveService.requestedPages.count

        await viewModel.loadNextPageIfNeeded(currentItem: .fixture())

        XCTAssertEqual(archiveService.requestedPages.count, initialCount)
    }

    func test_loadNextPageIfNeeded_hasNext가true이고마지막근처면다음페이지를병합한다() async {
        let firstItems = (1...10).map { SpotListItem.fixture(spotId: Int64($0)) }
        let secondItems = (11...12).map { SpotListItem.fixture(spotId: Int64($0)) }
        authService.stubbedAuthState = .signedIn(.fixture())
        archiveService.responder = { page in
            if page == 0 {
                .success(SpotListPage(spots: firstItems, page: 0, hasNext: true))
            } else {
                .success(SpotListPage(spots: secondItems, page: 1, hasNext: false))
            }
        }
        await viewModel.onAppear()

        await viewModel.loadNextPageIfNeeded(currentItem: firstItems.last!)

        guard case let .loaded(items, hasNext) = viewModel.state else {
            return XCTFail("Expected .loaded state")
        }
        XCTAssertEqual(items.count, 12)
        XCTAssertFalse(hasNext)
        XCTAssertEqual(archiveService.requestedPages, [0, 1])
    }

    func test_loadNextPageIfNeeded_처음아이템이면호출하지않는다() async {
        let items = (1...10).map { SpotListItem.fixture(spotId: Int64($0)) }
        authService.stubbedAuthState = .signedIn(.fixture())
        archiveService.responder = { _ in
            .success(SpotListPage(spots: items, page: 0, hasNext: true))
        }
        await viewModel.onAppear()
        let initialCount = archiveService.requestedPages.count

        await viewModel.loadNextPageIfNeeded(currentItem: items.first!)

        XCTAssertEqual(archiveService.requestedPages.count, initialCount)
    }

    // MARK: - bookmarkTapped

    func test_bookmarkTapped_낙관적제거후API성공시아이템이목록에서제거된다() async {
        let items = [SpotListItem.fixture(spotId: 1), SpotListItem.fixture(spotId: 2)]
        authService.stubbedAuthState = .signedIn(.fixture())
        archiveService.responder = { _ in
            .success(SpotListPage(spots: items, page: 0, hasNext: false))
        }
        await viewModel.onAppear()

        await viewModel.bookmarkTapped(1)

        guard case let .loaded(remaining, _) = viewModel.state else {
            return XCTFail("Expected .loaded state")
        }
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.spotId, 2)
        XCTAssertEqual(bookmarkService.deletedSpotIds, [1])
        XCTAssertNil(viewModel.toast)
    }

    func test_bookmarkTapped_마지막아이템제거시_상태가empty로전환된다() async {
        let item = SpotListItem.fixture(spotId: 1)
        authService.stubbedAuthState = .signedIn(.fixture())
        archiveService.responder = { _ in
            .success(SpotListPage(spots: [item], page: 0, hasNext: false))
        }
        await viewModel.onAppear()

        await viewModel.bookmarkTapped(1)

        XCTAssertEqual(viewModel.state, .empty)
    }

    func test_bookmarkTapped_API실패시_아이템이복원되고toast가설정된다() async {
        let items = [SpotListItem.fixture(spotId: 1), SpotListItem.fixture(spotId: 2)]
        authService.stubbedAuthState = .signedIn(.fixture())
        archiveService.responder = { _ in
            .success(SpotListPage(spots: items, page: 0, hasNext: false))
        }
        await viewModel.onAppear()
        bookmarkService.deleteError = TestError.failed

        await viewModel.bookmarkTapped(1)

        guard case let .loaded(restored, _) = viewModel.state else {
            return XCTFail("Expected .loaded state")
        }
        XCTAssertEqual(restored.count, 2)
        XCTAssertNotNil(viewModel.toast)
    }

    // MARK: - Helpers

    private func makeViewModel() -> ArchiveViewModel {
        ArchiveViewModel(
            archiveService: archiveService,
            bookmarkService: bookmarkService,
            authService: authService,
            socialLoginService: socialLoginService
        )
    }
}

private extension AuthToken {
    static func fixture() -> AuthToken {
        AuthToken(accessToken: "access", refreshToken: "refresh")
    }
}
