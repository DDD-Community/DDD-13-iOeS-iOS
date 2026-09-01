import XCTest
@testable import Pickflow

/// PV-40 — 스팟 상세의 추천/오픈 신청/철회/삭제 인터랙션.
@MainActor
final class SpotPublicationViewModelTests: XCTestCase {
    private var spotService: MockSpotService!
    private var mySpotService: MockMySpotService!
    private var bookmarkService: MockBookmarkService!
    private var locationService: MockLocationService!
    private var externalAppLauncher: MockExternalAppLauncher!
    private var shareSheetPresenter: MockShareSheetPresenter!
    private var analyticsLogger: MockAnalyticsLogger!
    private var tokenStore: MockTokenStore!
    private var openCompleteStore: InMemoryOpenCompleteStore!
    private var viewModel: SpotDetailViewModel!

    override func setUp() async throws {
        try await super.setUp()
        spotService = MockSpotService()
        mySpotService = MockMySpotService()
        bookmarkService = MockBookmarkService()
        locationService = MockLocationService()
        externalAppLauncher = MockExternalAppLauncher()
        shareSheetPresenter = MockShareSheetPresenter()
        analyticsLogger = MockAnalyticsLogger()
        tokenStore = MockTokenStore()
        tokenStore.storedToken = AuthToken(accessToken: "test-token", refreshToken: "test-refresh")
        openCompleteStore = InMemoryOpenCompleteStore()
        viewModel = makeViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
        openCompleteStore = nil
        tokenStore = nil
        analyticsLogger = nil
        shareSheetPresenter = nil
        externalAppLauncher = nil
        locationService = nil
        bookmarkService = nil
        mySpotService = nil
        spotService = nil
        try await super.tearDown()
    }

    // MARK: - 추천(좋아요)

    func test_toggleLike_비로그인이면_로그인유도되고_API를_호출하지_않는다() async {
        tokenStore.storedToken = nil
        await loadDetail(.fixture(likeCount: 3, isLiked: false, isLikeable: true))

        await viewModel.toggleLike()

        XCTAssertTrue(viewModel.isLoginRequired)
        XCTAssertTrue(spotService.likedSpotIds.isEmpty)
    }

    func test_toggleLike_추천전이면_서버최종값으로_카운트가_맞춰진다() async {
        await loadDetail(.fixture(likeCount: 3, isLiked: false, isLikeable: true))
        spotService.likeResult = .success(SpotLikeResponse(likeCount: 4, isLiked: true))

        await viewModel.toggleLike()

        XCTAssertEqual(spotService.likedSpotIds, [1])
        XCTAssertEqual(viewModel.likeCount, 4)
        XCTAssertTrue(viewModel.isLiked)
    }

    func test_toggleLike_성공하면_detailState의_스팟에도_반영된다() async {
        await loadDetail(.fixture(likeCount: 3, isLiked: false, isLikeable: true))
        spotService.likeResult = .success(SpotLikeResponse(likeCount: 4, isLiked: true))

        await viewModel.toggleLike()

        guard case let .loaded(spot) = viewModel.detailState else {
            return XCTFail("detailState 가 loaded 여야 한다")
        }
        XCTAssertEqual(spot.likeCount, 4)
        XCTAssertEqual(spot.isLiked, true)
    }

    func test_toggleLike_이미추천했으면_취소를_호출한다() async {
        await loadDetail(.fixture(likeCount: 4, isLiked: true, isLikeable: true))
        spotService.unlikeResult = .success(SpotLikeResponse(likeCount: 3, isLiked: false))

        await viewModel.toggleLike()

        XCTAssertEqual(spotService.unlikedSpotIds, [1])
        XCTAssertEqual(viewModel.likeCount, 3)
        XCTAssertFalse(viewModel.isLiked)
    }

    func test_toggleLike_실패하면_카운트와_상태가_롤백되고_토스트가_뜬다() async {
        await loadDetail(.fixture(likeCount: 3, isLiked: false, isLikeable: true))
        spotService.likeResult = .failure(TestError.failed)

        await viewModel.toggleLike()

        XCTAssertEqual(viewModel.likeCount, 3)
        XCTAssertFalse(viewModel.isLiked)
        XCTAssertEqual(viewModel.toast, "잠시 후 다시 시도해주세요.")
    }

    func test_toggleLike_연타해도_요청은_한번만_나간다() async {
        await loadDetail(.fixture(likeCount: 3, isLiked: false, isLikeable: true))

        let vm = viewModel!
        async let first: Void = vm.toggleLike()
        async let second: Void = vm.toggleLike()
        _ = await (first, second)

        XCTAssertEqual(spotService.likedSpotIds.count, 1)
    }

    func test_추천버튼은_공개된_스팟에만_노출된다() async {
        await loadDetail(.fixture(isMySpot: true, status: .draft, isLikeable: false))
        XCTAssertFalse(viewModel.canLike)

        let published = makeViewModel()
        viewModel = published
        await loadDetail(.fixture(isMySpot: true, status: .published, isLikeable: true))
        XCTAssertTrue(viewModel.canLike)
    }

    // MARK: - 오픈 신청

    func test_requestOpen_성공하면_검수중으로_바뀌고_접수토스트가_뜬다() async {
        await loadDetail(.fixture(isMySpot: true, status: .draft))
        mySpotService.requestOpenResult = .success(OpenMySpotResponse(spotId: 1, status: .pending))

        await viewModel.confirmOpenRequest()

        XCTAssertEqual(mySpotService.requestedOpenSpotIds, [1])
        XCTAssertEqual(viewModel.publicationStatus, .pending)
        XCTAssertEqual(viewModel.toast, "오픈 신청이 접수되었어요.")
        XCTAssertNil(viewModel.activeSheet)
    }

    func test_requestOpen_반려상태에서_재신청하면_재검토대기가_된다() async {
        await loadDetail(.fixture(isMySpot: true, status: .rejected))
        mySpotService.requestOpenResult = .success(OpenMySpotResponse(spotId: 1, status: .reReviewPending))

        await viewModel.confirmOpenRequest()

        XCTAssertEqual(viewModel.publicationStatus, .reReviewPending)
    }

    func test_requestOpen_실패하면_상태가_유지되고_실패토스트가_뜬다() async {
        await loadDetail(.fixture(isMySpot: true, status: .draft))
        mySpotService.requestOpenResult = .failure(TestError.failed)

        await viewModel.confirmOpenRequest()

        XCTAssertEqual(viewModel.publicationStatus, .draft)
        XCTAssertEqual(viewModel.toast, "실패했어요, 다시 시도해주세요.")
    }

    // MARK: - 공개 해제 (철회 / 비공개 전환)

    func test_cancelPublication_검수중이었으면_나만보기로_돌아간다() async {
        await loadDetail(.fixture(isMySpot: true, status: .pending))
        mySpotService.cancelPublicationResult = .success(
            CancelPublicationResponse(spotId: 1, previousStatus: .pending, status: .draft)
        )

        await viewModel.confirmCancelPublication()

        XCTAssertEqual(mySpotService.cancelledSpotIds, [1])
        XCTAssertEqual(viewModel.publicationStatus, .draft)
        XCTAssertNil(viewModel.activeSheet)
    }

    func test_cancelPublication_공개중이었으면_비공개로_전환된다() async {
        await loadDetail(.fixture(isMySpot: true, status: .published))
        mySpotService.cancelPublicationResult = .success(
            CancelPublicationResponse(spotId: 1, previousStatus: .published, status: .draft)
        )

        await viewModel.confirmCancelPublication()

        XCTAssertEqual(viewModel.publicationStatus, .draft)
    }

    func test_cancelPublication_반려상태에서도_공개해제API를_호출하고_배너상태를_지운다() async {
        await loadDetail(.fixture(
            isMySpot: true,
            status: .rejected,
            rejection: SpotRejectionInfo(
                reason: "FILTER_MISMATCH",
                reasonLabel: "카테고리 불일치",
                guideMessage: "선택하신 카테고리와 사진이 일치하지 않습니다.",
                detail: nil,
                rejectedAt: "2026-07-21T10:00:00Z"
            )
        ))
        mySpotService.cancelPublicationResult = .success(
            CancelPublicationResponse(spotId: 1, previousStatus: .rejected, status: .draft)
        )

        await viewModel.confirmCancelPublication()

        XCTAssertEqual(mySpotService.cancelledSpotIds, [1])
        XCTAssertEqual(viewModel.publicationStatus, .draft)
        guard case let .loaded(spot) = viewModel.detailState else {
            return XCTFail("상세 상태가 유지되어야 합니다.")
        }
        XCTAssertEqual(spot.status, .draft)
        XCTAssertNil(spot.rejection)
    }

    func test_cancelPublication_직전에_검수가_확정되면_이미처리안내후_상세를_다시_읽는다() async {
        await loadDetail(.fixture(isMySpot: true, status: .pending))
        mySpotService.cancelPublicationResult = .failure(
            APIError(code: "SP004", message: "이미 처리된 신청입니다.", statusCode: 409)
        )
        spotService.result = .success(.fixture(isMySpot: true, status: .published, isLikeable: true))

        await viewModel.confirmCancelPublication()

        XCTAssertEqual(viewModel.toast, "이미 처리된 신청이에요.")
        XCTAssertEqual(viewModel.publicationStatus, .published)
    }

    // MARK: - 삭제

    func test_deleteMySpot_성공하면_화면이_닫힌다() async {
        await loadDetail(.fixture(isMySpot: true, status: .draft))

        await viewModel.confirmDelete()

        XCTAssertEqual(mySpotService.deletedSpotIds, [1])
        XCTAssertTrue(viewModel.dismissRequested)
    }

    func test_deleteMySpot_검수중이라_거절되면_철회안내_토스트가_뜬다() async {
        await loadDetail(.fixture(isMySpot: true, status: .pending))
        mySpotService.deleteError = APIError(
            code: "SP011", message: "검수 중인 스팟은 삭제할 수 없습니다.", statusCode: 409
        )

        await viewModel.confirmDelete()

        XCTAssertFalse(viewModel.dismissRequested)
        XCTAssertEqual(viewModel.toast, "오픈 신청을 먼저 철회한 뒤 삭제할 수 있어요.")
    }

    // MARK: - 시트 표시

    func test_시트는_한번에_하나만_열린다() async {
        await loadDetail(.fixture(isMySpot: true, status: .draft))

        viewModel.presentSheet(.openRequest)
        XCTAssertEqual(viewModel.activeSheet, .openRequest)

        viewModel.presentSheet(.delete)
        XCTAssertEqual(viewModel.activeSheet, .delete)

        viewModel.dismissSheet()
        XCTAssertNil(viewModel.activeSheet)
    }

    func test_오픈완료팝업은_승인된_내스팟에_처음_진입할때만_뜬다() async {
        await loadDetail(.fixture(isMySpot: true, status: .published, isLikeable: true))
        XCTAssertTrue(viewModel.isOpenCompletePresented)

        viewModel.acknowledgeOpenComplete()
        XCTAssertFalse(viewModel.isOpenCompletePresented)
    }

    // MARK: - Helpers

    private func makeViewModel() -> SpotDetailViewModel {
        SpotDetailViewModel(
            spotId: 1,
            spotService: spotService,
            mySpotService: mySpotService,
            bookmarkService: bookmarkService,
            locationService: locationService,
            externalAppLauncher: externalAppLauncher,
            shareSheetPresenter: shareSheetPresenter,
            analyticsLogger: analyticsLogger,
            tokenStore: tokenStore,
            deviceIdProvider: { "device-1" },
            clock: { Date(timeIntervalSince1970: 0) },
            openCompleteStore: openCompleteStore
        )
    }

    private func loadDetail(_ detail: SpotDetail) async {
        spotService.result = .success(detail)
        viewModel.updateDetent(.large)
        for _ in 0..<100 where viewModel.detailState == .idle || viewModel.detailState == .loading {
            await Task.yield()
        }
    }
}

final class InMemoryOpenCompleteStore: OpenCompleteAcknowledging, @unchecked Sendable {
    private var acknowledged: Set<Int64> = []

    func hasAcknowledged(spotId: Int64) -> Bool { acknowledged.contains(spotId) }
    func acknowledge(spotId: Int64) { acknowledged.insert(spotId) }
}

/// PV-40 — 유저 등록 스팟을 북마크할 때의 사전 안내.
@MainActor
final class SpotBookmarkNoticeTests: XCTestCase {
    private var spotService: MockSpotService!
    private var bookmarkService: MockBookmarkService!
    private var tokenStore: MockTokenStore!

    override func setUp() async throws {
        try await super.setUp()
        spotService = MockSpotService()
        bookmarkService = MockBookmarkService()
        tokenStore = MockTokenStore()
        tokenStore.storedToken = AuthToken(accessToken: "t", refreshToken: "r")
    }

    override func tearDown() async throws {
        tokenStore = nil
        bookmarkService = nil
        spotService = nil
        try await super.tearDown()
    }

    func test_유저등록_스팟을_북마크하면_비공개_전환_가능성을_알린다() async {
        let viewModel = await makeLoadedViewModel(isCurated: false)

        await viewModel.toggleBookmark()

        XCTAssertEqual(viewModel.toast, "작성자가 언제든 비공개로 전환할 수 있어요")
    }

    func test_큐레이션_스팟에는_안내하지_않는다() async {
        let viewModel = await makeLoadedViewModel(isCurated: true)

        await viewModel.toggleBookmark()

        XCTAssertNil(viewModel.toast)
    }

    func test_북마크를_해제할_때는_안내하지_않는다() async {
        let viewModel = await makeLoadedViewModel(isCurated: false, isBookmarked: true)

        await viewModel.toggleBookmark()

        XCTAssertNil(viewModel.toast)
    }

    private func makeLoadedViewModel(isCurated: Bool, isBookmarked: Bool = false) async -> SpotDetailViewModel {
        spotService.result = .success(
            .fixture(isBookmarked: isBookmarked, isMySpot: false, status: .published, isCurated: isCurated)
        )
        let viewModel = SpotDetailViewModel(
            spotId: 1,
            spotService: spotService,
            mySpotService: MockMySpotService(),
            bookmarkService: bookmarkService,
            locationService: MockLocationService(),
            externalAppLauncher: MockExternalAppLauncher(),
            shareSheetPresenter: MockShareSheetPresenter(),
            analyticsLogger: MockAnalyticsLogger(),
            tokenStore: tokenStore,
            deviceIdProvider: { "d" },
            clock: { Date(timeIntervalSince1970: 0) },
            openCompleteStore: InMemoryOpenCompleteStore()
        )
        viewModel.updateDetent(.large)
        for _ in 0..<100 where viewModel.detailState == .idle || viewModel.detailState == .loading {
            await Task.yield()
        }
        return viewModel
    }
}
