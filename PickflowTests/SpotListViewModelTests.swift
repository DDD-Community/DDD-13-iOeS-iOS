import XCTest
@testable import Pickflow

@MainActor
final class SpotListViewModelTests: XCTestCase {
    private var spotListService: MockSpotListService!
    private var bookmarkService: MockBookmarkService!
    private var locationService: MockLocationService!
    private var tokenStore: MockTokenStore!
    private var viewModel: SpotListViewModel!

    override func setUp() async throws {
        try await super.setUp()
        spotListService = MockSpotListService()
        bookmarkService = MockBookmarkService()
        locationService = MockLocationService()
        tokenStore = MockTokenStore()
        tokenStore.storedToken = AuthToken(accessToken: "t", refreshToken: "r")
        viewModel = makeViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
        tokenStore = nil
        locationService = nil
        bookmarkService = nil
        spotListService = nil
        try await super.tearDown()
    }

    // MARK: - onAppear

    func test_onAppear_권한허용_정상응답_상태가loaded로전환된다() async {
        spotListService.responder = { _ in
            .success(SpotListPage(spots: [.fixture()], page: 0, hasNext: false))
        }

        await viewModel.onAppear()

        XCTAssertEqual(viewModel.state, .loaded(items: [.fixture()], hasNext: false))
        XCTAssertEqual(spotListService.requests.count, 1)
        XCTAssertEqual(spotListService.requests.first?.page, 0)
        XCTAssertEqual(spotListService.requests.first?.latitude, 37.1)
        XCTAssertEqual(spotListService.requests.first?.longitude, 127.1)
    }

    func test_onAppear_권한거부시_sort가recommended로기본설정되고좌표없이fetch를호출한다() async {
        locationService.stubbedAuthorizationStatus = .denied
        spotListService.responder = { _ in
            .success(SpotListPage(spots: [.fixture()], page: 0, hasNext: false))
        }

        await viewModel.onAppear()

        XCTAssertEqual(viewModel.sort, .recommended)
        XCTAssertEqual(spotListService.requests.count, 1)
        XCTAssertNil(spotListService.requests.first?.latitude)
        XCTAssertNil(spotListService.requests.first?.longitude)
        XCTAssertEqual(spotListService.requests.first?.sort, .recommended)
    }

    func test_sortChanged_권한거부상태에서distance선택시_팝업이뜨고sort는변경되지않는다() async {
        locationService.stubbedAuthorizationStatus = .denied
        spotListService.responder = { _ in
            .success(SpotListPage(spots: [.fixture()], page: 0, hasNext: false))
        }
        await viewModel.onAppear()
        let beforeCount = spotListService.requests.count

        await viewModel.sortChanged(.distance)

        XCTAssertTrue(viewModel.showLocationPermissionPrompt)
        XCTAssertEqual(viewModel.sort, .recommended)
        XCTAssertEqual(spotListService.requests.count, beforeCount)
    }

    func test_onAppear_빈응답시_상태가empty로전환된다() async {
        spotListService.responder = { _ in
            .success(SpotListPage(spots: [], page: 0, hasNext: false))
        }

        await viewModel.onAppear()

        XCTAssertEqual(viewModel.state, .empty)
    }

    func test_onAppear_fetch실패시_상태가failed로전환된다() async {
        spotListService.responder = { _ in .failure(TestError.failed) }

        await viewModel.onAppear()

        guard case let .failed(message) = viewModel.state else {
            return XCTFail("Expected failed state")
        }
        XCTAssertTrue(message.contains("test failure"))
    }

    func test_onAppear_위치조회실패시_좌표없이fetch를호출한다() async {
        locationService.result = .failure(TestError.failed)
        spotListService.responder = { _ in
            .success(SpotListPage(spots: [.fixture()], page: 0, hasNext: false))
        }

        await viewModel.onAppear()

        XCTAssertEqual(spotListService.requests.count, 1)
        XCTAssertNil(spotListService.requests.first?.latitude)
        XCTAssertNil(spotListService.requests.first?.longitude)
    }

    // MARK: - themeTapped

    func test_themeTapped_새카테고리선택시_selectedThemes에추가되고page0부터재호출한다() async {
        spotListService.responder = { _ in
            .success(SpotListPage(spots: [.fixture()], page: 0, hasNext: false))
        }
        await viewModel.onAppear()

        await viewModel.themeTapped(.sunset)

        XCTAssertEqual(viewModel.selectedThemes, [.sunset])
        XCTAssertEqual(spotListService.requests.count, 2)
        XCTAssertEqual(spotListService.requests.last?.themes, [.sunset])
        XCTAssertEqual(spotListService.requests.last?.page, 0)
    }

    func test_themeTapped_동일카테고리재탭시_선택이해제되고재호출한다() async {
        spotListService.responder = { _ in
            .success(SpotListPage(spots: [.fixture()], page: 0, hasNext: false))
        }
        await viewModel.onAppear()
        await viewModel.themeTapped(.sunset)

        await viewModel.themeTapped(.sunset)

        XCTAssertTrue(viewModel.selectedThemes.isEmpty)
        XCTAssertEqual(spotListService.requests.last?.themes, [])
    }

    func test_themeTapped_다른카테고리추가선택시_둘다유지한채재호출한다() async {
        spotListService.responder = { _ in
            .success(SpotListPage(spots: [.fixture()], page: 0, hasNext: false))
        }
        await viewModel.onAppear()
        await viewModel.themeTapped(.sunset)

        await viewModel.themeTapped(.nightView)

        XCTAssertEqual(viewModel.selectedThemes, [.sunset, .nightView])
        XCTAssertEqual(spotListService.requests.last?.themes, [.sunset, .nightView])
    }

    // MARK: - sortChanged

    func test_sortChanged_동일정렬은무시되고재호출하지않는다() async {
        spotListService.responder = { _ in
            .success(SpotListPage(spots: [.fixture()], page: 0, hasNext: false))
        }
        await viewModel.onAppear()
        let initialCount = spotListService.requests.count

        await viewModel.sortChanged(.distance)

        XCTAssertEqual(spotListService.requests.count, initialCount)
    }

    func test_sortChanged_다른정렬선택시_sort가변경되고재호출한다() async {
        spotListService.responder = { _ in
            .success(SpotListPage(spots: [.fixture()], page: 0, hasNext: false))
        }
        await viewModel.onAppear()

        await viewModel.sortChanged(.recommended)

        XCTAssertEqual(viewModel.sort, .recommended)
        XCTAssertEqual(spotListService.requests.last?.page, 0)
    }

    // MARK: - loadNextPageIfNeeded

    func test_loadNextPageIfNeeded_hasNext가false면호출하지않는다() async {
        let firstPage = SpotListPage(spots: [.fixture()], page: 0, hasNext: false)
        spotListService.responder = { _ in .success(firstPage) }
        await viewModel.onAppear()
        let initialCount = spotListService.requests.count

        await viewModel.loadNextPageIfNeeded(currentItem: .fixture())

        XCTAssertEqual(spotListService.requests.count, initialCount)
    }

    func test_loadNextPageIfNeeded_hasNext가true이고마지막근처면다음페이지를병합한다() async {
        let firstItems = (1...10).map { SpotListItem.fixture(spotId: Int64($0)) }
        let secondItems = (11...12).map { SpotListItem.fixture(spotId: Int64($0)) }
        spotListService.responder = { request in
            if request.page == 0 {
                .success(SpotListPage(spots: firstItems, page: 0, hasNext: true))
            } else {
                .success(SpotListPage(spots: secondItems, page: 1, hasNext: false))
            }
        }
        await viewModel.onAppear()

        await viewModel.loadNextPageIfNeeded(currentItem: firstItems.last!)

        XCTAssertEqual(viewModel.state, .loaded(items: firstItems + secondItems, hasNext: false))
        XCTAssertEqual(spotListService.requests.last?.page, 1)
    }

    // MARK: - bookmarkTapped

    func test_bookmarkTapped_비로그인시_showLoginPrompt가true가되고API를호출하지않는다() async {
        tokenStore.storedToken = nil

        await viewModel.bookmarkTapped(1)

        XCTAssertTrue(viewModel.showLoginPrompt)
        XCTAssertTrue(bookmarkService.addedSpotIds.isEmpty)
        XCTAssertFalse(viewModel.isBookmarked(1))
    }

    func test_bookmarkTapped_로그인_미북마크상태에서_낙관적으로true가되고add가호출된다() async {
        await viewModel.bookmarkTapped(1)

        XCTAssertTrue(viewModel.isBookmarked(1))
        XCTAssertEqual(bookmarkService.addedSpotIds, [1])
    }

    func test_bookmarkTapped_로그인_북마크상태에서_낙관적으로false가되고delete가호출된다() async {
        await viewModel.bookmarkTapped(1)

        await viewModel.bookmarkTapped(1)

        XCTAssertFalse(viewModel.isBookmarked(1))
        XCTAssertEqual(bookmarkService.deletedSpotIds, [1])
    }

    func test_bookmarkTapped_API실패시_상태가롤백되고toast가설정된다() async {
        bookmarkService.addError = TestError.failed

        await viewModel.bookmarkTapped(1)

        XCTAssertFalse(viewModel.isBookmarked(1))
        XCTAssertEqual(viewModel.toast, "북마크 변경에 실패했어요.")
    }

    func test_bookmarkTapped_409Conflict는성공으로처리된다() async {
        bookmarkService.addError = BookmarkError.alreadyBookmarked

        await viewModel.bookmarkTapped(1)

        XCTAssertTrue(viewModel.isBookmarked(1))
        XCTAssertNil(viewModel.toast)
    }

    // MARK: - Helpers

    private func makeViewModel() -> SpotListViewModel {
        SpotListViewModel(
            spotListService: spotListService,
            bookmarkService: bookmarkService,
            locationService: locationService,
            tokenStore: tokenStore
        )
    }
}
