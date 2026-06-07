import XCTest
@testable import Pickflow

@MainActor
final class SpotDetailViewModelTests: XCTestCase {
    private var spotService: MockSpotService!
    private var bookmarkService: MockBookmarkService!
    private var locationService: MockLocationService!
    private var externalAppLauncher: MockExternalAppLauncher!
    private var shareSheetPresenter: MockShareSheetPresenter!
    private var analyticsLogger: MockAnalyticsLogger!
    private var tokenStore: MockTokenStore!
    private var viewModel: SpotDetailViewModel!

    override func setUp() async throws {
        try await super.setUp()
        spotService = MockSpotService()
        bookmarkService = MockBookmarkService()
        locationService = MockLocationService()
        externalAppLauncher = MockExternalAppLauncher()
        shareSheetPresenter = MockShareSheetPresenter()
        analyticsLogger = MockAnalyticsLogger()
        tokenStore = MockTokenStore()
        tokenStore.storedToken = AuthToken(accessToken: "test-token", refreshToken: "test-refresh")
        viewModel = makeViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
        tokenStore = nil
        analyticsLogger = nil
        shareSheetPresenter = nil
        externalAppLauncher = nil
        locationService = nil
        bookmarkService = nil
        spotService = nil
        try await super.tearDown()
    }

    func test_onAppear_상세조회성공_상태가loaded로전환된다() async throws {
        await viewModel.onAppear()
        await loadDetail()

        XCTAssertEqual(viewModel.detailState, .loaded(.fixture()))
        XCTAssertFalse(viewModel.isBookmarked)
    }

    func test_onAppear_상세조회실패_상태가failed로전환되고에러메시지가포함된다() async throws {
        spotService.result = .failure(TestError.failed)

        await viewModel.onAppear()
        await loadDetail()

        guard case let .failed(message) = viewModel.detailState else {
            return XCTFail("Expected failed state")
        }
        XCTAssertTrue(message.contains("test failure"))
    }

    func test_onAppear_위치권한실패시_좌표없이상세조회를호출한다() async throws {
        locationService.result = .failure(TestError.failed)

        await viewModel.onAppear()
        await loadDetail()

        XCTAssertEqual(spotService.requests.first?.id, 1)
        XCTAssertNil(spotService.requests.first?.latitude)
        XCTAssertNil(spotService.requests.first?.longitude)
    }

    func test_onAppear_detail은즉시fetch되지않고preview만로드된다() async throws {
        await viewModel.onAppear()

        XCTAssertEqual(viewModel.detailState, .idle)
        XCTAssertTrue(spotService.requests.isEmpty, "detail requests should be empty before sheet large")
    }

    func test_updateDetent_large_detail이fetch된다() async throws {
        await viewModel.onAppear()

        viewModel.updateDetent(.large)
        await loadDetail()

        XCTAssertEqual(viewModel.detailState, .loaded(.fixture()))
        XCTAssertEqual(spotService.requests.count, 1)
    }

    func test_updateDetent_large_이미loaded면_detail재호출하지않는다() async throws {
        await viewModel.onAppear()
        viewModel.updateDetent(.large)
        await loadDetail()
        XCTAssertEqual(spotService.requests.count, 1)

        viewModel.updateDetent(.medium)
        viewModel.updateDetent(.large)
        await Task.yield()
        await Task.yield()

        XCTAssertEqual(spotService.requests.count, 1, "detail must be cached")
    }

    func test_toggleBookmark_비로그인시_isLoginRequired가true로설정된다() async throws {
        tokenStore.storedToken = nil
        await viewModel.onAppear()

        await viewModel.toggleBookmark()

        XCTAssertTrue(viewModel.isLoginRequired)
        XCTAssertTrue(bookmarkService.addedSpotIds.isEmpty)
    }

    func test_toggleBookmark_미북마크상태에서_낙관적으로true가되고_POST가호출된다() async throws {
        await viewModel.onAppear()
        await loadDetail()

        await viewModel.toggleBookmark()

        XCTAssertTrue(viewModel.isBookmarked)
        XCTAssertEqual(bookmarkService.addedSpotIds, [1])
    }

    func test_toggleBookmark_API실패시_상태가롤백되고toast가설정된다() async throws {
        bookmarkService.addError = TestError.failed
        await viewModel.onAppear()
        await loadDetail()

        await viewModel.toggleBookmark()

        XCTAssertFalse(viewModel.isBookmarked)
        XCTAssertEqual(viewModel.toast, "북마크 변경에 실패했어요.")
    }

    func test_toggleBookmark_409Conflict는성공으로처리된다() async throws {
        bookmarkService.addError = BookmarkError.alreadyBookmarked
        await viewModel.onAppear()
        await loadDetail()

        await viewModel.toggleBookmark()

        XCTAssertTrue(viewModel.isBookmarked)
        XCTAssertNil(viewModel.toast)
    }

    func test_toggleBookmark_북마크상태에서_낙관적으로false가되고_DELETE가호출된다() async throws {
        spotService.result = .success(.fixture(isBookmarked: true))
        await viewModel.onAppear()
        await loadDetail()

        await viewModel.toggleBookmark()

        XCTAssertFalse(viewModel.isBookmarked)
        XCTAssertEqual(bookmarkService.deletedSpotIds, [1])
    }

    func test_openNaverMapsRoute_네이버지도설치되어있으면_nmap스킴URL을연다() async throws {
        await viewModel.onAppear()
        await loadDetail()

        viewModel.openNaverMapsRoute()
        await waitForNaverMapsOpen()

        XCTAssertEqual(externalAppLauncher.openedURLs.first?.scheme, "nmap")
    }

    func test_openNaverMapsRoute_네이버지도미설치면_AppStoreURL을연다() async throws {
        externalAppLauncher.isNaverMapInstalled = false
        await viewModel.onAppear()
        await loadDetail()

        viewModel.openNaverMapsRoute()
        await waitForNaverMapsOpen()

        XCTAssertEqual(externalAppLauncher.openedURLs.first?.absoluteString, "https://apps.apple.com/kr/app/id311867728")
    }

    func test_share_shareSheet가표시되고URL이포함된다() async throws {
        await viewModel.onAppear()
        await loadDetail()

        viewModel.share()
        await waitForShareSheet()

        XCTAssertEqual(shareSheetPresenter.presentedItems.count, 1)
        XCTAssertTrue(shareSheetPresenter.presentedItems[0][0].contains("https://pickflow-api.us/"))
    }

    func test_share_detail미로드시에도_shareSheet는표시된다() async throws {
        await viewModel.onAppear()

        viewModel.share()
        await waitForShareSheet()

        XCTAssertEqual(shareSheetPresenter.presentedItems.count, 1)
    }

    func test_close_dismissRequested가true로설정된다() {
        viewModel.close()

        XCTAssertTrue(viewModel.dismissRequested)
    }

    func test_reportInvalidInfo_신고API가호출되고성공토스트가설정된다() async {
        await viewModel.onAppear()
        await loadDetail()

        viewModel.reportInvalidInfo(content: "실제 위치가 지도와 달라요")
        await waitForReport()

        XCTAssertEqual(spotService.reportedSpotIds, [1])
        XCTAssertEqual(spotService.reportedContents, ["실제 위치가 지도와 달라요"])
        XCTAssertEqual(viewModel.toast, "제보가 접수되었습니다.")
    }

    func test_reportInvalidInfo_API실패시_실패토스트가설정된다() async {
        spotService.reportError = TestError.failed
        await viewModel.onAppear()
        await loadDetail()

        viewModel.reportInvalidInfo(content: "내용")
        await waitForReport()

        XCTAssertEqual(viewModel.toast, "제보 접수에 실패했어요.")
    }

    func test_reportInvalidInfo_loaded상태가아니면_API를호출하지않는다() {
        viewModel.reportInvalidInfo(content: "내용")

        XCTAssertTrue(spotService.reportedSpotIds.isEmpty)
    }

    func test_notifyUpdateRequested_분석이벤트로깅과_토스트가설정된다() {
        viewModel.notifyUpdateRequested()

        XCTAssertEqual(viewModel.updateNotificationToast, "추후 업데이트 시, 가장 먼저 알림 보내드릴게요!")
        XCTAssertEqual(analyticsLogger.loggedEvents.count, 1)
        XCTAssertEqual(analyticsLogger.loggedEvents.first?.name, ShareFakedoorAnalyticsEvent.notifyButtonTap.name)
    }

    private func makeViewModel() -> SpotDetailViewModel {
        SpotDetailViewModel(
            spotId: 1,
            spotService: spotService,
            bookmarkService: bookmarkService,
            locationService: locationService,
            externalAppLauncher: externalAppLauncher,
            shareSheetPresenter: shareSheetPresenter,
            analyticsLogger: analyticsLogger,
            tokenStore: tokenStore,
            deviceIdProvider: { "device-1" },
            clock: { Date(timeIntervalSince1970: 0) }
        )
    }

    /// 새 lazy detail 로딩 정책에 맞춰, large detent 트리거 후 detail load 완료를 대기.
    private func loadDetail() async {
        viewModel.updateDetent(.large)
        for _ in 0..<100 where viewModel.detailState == .idle || viewModel.detailState == .loading {
            await Task.yield()
        }
    }

    private func waitForNaverMapsOpen() async {
        for _ in 0..<50 where externalAppLauncher.openedURLs.isEmpty {
            await Task.yield()
        }
    }

    private func waitForShareSheet() async {
        for _ in 0..<20 where shareSheetPresenter.presentedItems.isEmpty {
            await Task.yield()
        }
    }

    private func waitForReport() async {
        for _ in 0..<50 where spotService.reportedSpotIds.isEmpty {
            await Task.yield()
        }
        for _ in 0..<50 where viewModel.toast == nil {
            await Task.yield()
        }
    }

    // MARK: - presentationPhase (KAN-99)

    func test_초기상태_presentationPhase는sheetMedium이다() {
        XCTAssertEqual(viewModel.presentationPhase, .sheetMedium)
    }

    func test_promoteToFullCover_호출시_phase가fullCover로전환된다() {
        viewModel.promoteToFullCover()

        XCTAssertEqual(viewModel.presentationPhase, .fullCover)
    }

    func test_demoteToSheet_fullCover에서호출시_phase가sheetLarge로전환된다() {
        viewModel.promoteToFullCover()

        viewModel.demoteToSheet()

        XCTAssertEqual(viewModel.presentationPhase, .sheetLarge)
    }

    func test_updateDetent_medium지정시_phase가sheetMedium으로전환된다() {
        viewModel.promoteToFullCover()

        viewModel.updateDetent(.medium)

        XCTAssertEqual(viewModel.presentationPhase, .sheetMedium)
    }

    func test_updateDetent_large지정시_phase가sheetLarge로전환된다() {
        viewModel.updateDetent(.large)

        XCTAssertEqual(viewModel.presentationPhase, .sheetLarge)
    }
}
