import XCTest
@testable import Pickflow

@MainActor
final class SpotDetailViewModelTests: XCTestCase {
    private var spotService: MockSpotService!
    private var bookmarkService: MockBookmarkService!
    private var shareIntentService: MockShareIntentService!
    private var locationService: MockLocationService!
    private var externalAppLauncher: MockExternalAppLauncher!
    private var shareSheetPresenter: MockShareSheetPresenter!
    private var viewModel: SpotDetailViewModel!

    override func setUp() async throws {
        try await super.setUp()
        spotService = MockSpotService()
        bookmarkService = MockBookmarkService()
        shareIntentService = MockShareIntentService()
        locationService = MockLocationService()
        externalAppLauncher = MockExternalAppLauncher()
        shareSheetPresenter = MockShareSheetPresenter()
        viewModel = makeViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
        shareSheetPresenter = nil
        externalAppLauncher = nil
        locationService = nil
        shareIntentService = nil
        bookmarkService = nil
        spotService = nil
        try await super.tearDown()
    }

    func test_onAppear_상세조회성공_상태가loaded로전환된다() async throws {
        await viewModel.onAppear()

        XCTAssertEqual(viewModel.state, .loaded(.fixture()))
        XCTAssertFalse(viewModel.isBookmarked)
    }

    func test_onAppear_상세조회실패_상태가failed로전환되고에러메시지가포함된다() async throws {
        spotService.result = .failure(TestError.failed)

        await viewModel.onAppear()

        guard case let .failed(message) = viewModel.state else {
            return XCTFail("Expected failed state")
        }
        XCTAssertTrue(message.contains("test failure"))
    }

    func test_onAppear_위치권한실패시_좌표없이상세조회를호출한다() async throws {
        locationService.result = .failure(TestError.failed)

        await viewModel.onAppear()

        XCTAssertEqual(spotService.requests.first?.id, 1)
        XCTAssertNil(spotService.requests.first?.latitude)
        XCTAssertNil(spotService.requests.first?.longitude)
    }

    func test_toggleBookmark_미북마크상태에서_낙관적으로true가되고_POST가호출된다() async throws {
        await viewModel.onAppear()

        await viewModel.toggleBookmark()

        XCTAssertTrue(viewModel.isBookmarked)
        XCTAssertEqual(bookmarkService.addedSpotIds, [1])
    }

    func test_toggleBookmark_API실패시_상태가롤백되고toast가설정된다() async throws {
        bookmarkService.addError = TestError.failed
        await viewModel.onAppear()

        await viewModel.toggleBookmark()

        XCTAssertFalse(viewModel.isBookmarked)
        XCTAssertEqual(viewModel.toast, "북마크 변경에 실패했어요.")
    }

    func test_toggleBookmark_409Conflict는성공으로처리된다() async throws {
        bookmarkService.addError = BookmarkError.alreadyBookmarked
        await viewModel.onAppear()

        await viewModel.toggleBookmark()

        XCTAssertTrue(viewModel.isBookmarked)
        XCTAssertNil(viewModel.toast)
    }

    func test_toggleBookmark_북마크상태에서_낙관적으로false가되고_DELETE가호출된다() async throws {
        spotService.result = .success(.fixture(isBookmarked: true))
        await viewModel.onAppear()

        await viewModel.toggleBookmark()

        XCTAssertFalse(viewModel.isBookmarked)
        XCTAssertEqual(bookmarkService.deletedSpotIds, [1])
    }

    func test_openNaverMapsRoute_네이버지도설치되어있으면_nmap스킴URL을연다() async throws {
        await viewModel.onAppear()

        viewModel.openNaverMapsRoute()

        XCTAssertEqual(externalAppLauncher.openedURLs.first?.scheme, "nmap")
    }

    func test_openNaverMapsRoute_네이버지도미설치면_AppStoreURL을연다() async throws {
        externalAppLauncher.isNaverMapInstalled = false
        await viewModel.onAppear()

        viewModel.openNaverMapsRoute()

        XCTAssertEqual(externalAppLauncher.openedURLs.first?.absoluteString, "https://apps.apple.com/kr/app/id311867728")
    }

    func test_share_share_intents가호출되고_shareSheet가표시된다() async throws {
        await viewModel.onAppear()

        viewModel.share()
        await waitForShareIntent()

        XCTAssertEqual(shareIntentService.deviceIds, ["device-1"])
        XCTAssertEqual(shareSheetPresenter.presentedItems.count, 1)
        XCTAssertTrue(shareSheetPresenter.presentedItems[0][0].contains("https://pickflow.app/spot/1"))
    }

    func test_share_share_intents_API실패시에도_shareSheet는표시된다() async throws {
        shareIntentService.error = TestError.failed
        await viewModel.onAppear()

        viewModel.share()
        await waitForShareIntent()

        XCTAssertEqual(shareSheetPresenter.presentedItems.count, 1)
    }

    func test_close_dismissRequested가true로설정된다() {
        viewModel.close()

        XCTAssertTrue(viewModel.dismissRequested)
    }

    private func makeViewModel() -> SpotDetailViewModel {
        SpotDetailViewModel(
            spotId: 1,
            spotService: spotService,
            bookmarkService: bookmarkService,
            shareIntentService: shareIntentService,
            locationService: locationService,
            externalAppLauncher: externalAppLauncher,
            shareSheetPresenter: shareSheetPresenter,
            deviceIdProvider: { "device-1" },
            clock: { Date(timeIntervalSince1970: 0) }
        )
    }

    private func waitForShareIntent() async {
        for _ in 0..<20 where shareIntentService.deviceIds.isEmpty {
            await Task.yield()
        }
    }
}
