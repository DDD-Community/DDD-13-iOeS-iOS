import XCTest
@testable import Pickflow

/// PV-40 — 검수 결과 스낵바와 저장 탭 인디케이터.
/// spot-open-review-histories API 를 단일 진실 소스로 쓴다.
@MainActor
final class SpotReviewNoticeTests: XCTestCase {
    private var archiveService: MockArchiveService!
    private var reviewHistoryService: MockSpotReviewHistoryService!
    private var tokenStore: MockTokenStore!

    override func setUp() async throws {
        try await super.setUp()
        archiveService = MockArchiveService()
        reviewHistoryService = MockSpotReviewHistoryService()
        tokenStore = MockTokenStore()
        tokenStore.storedToken = AuthToken(accessToken: "t", refreshToken: "r")
    }

    override func tearDown() async throws {
        tokenStore = nil
        reviewHistoryService = nil
        archiveService = nil
        try await super.tearDown()
    }

    // MARK: - 결과 감지

    func test_승인_히스토리가_있으면_승인_스낵바가_뜬다() async {
        reviewHistoryService.historiesResult = .success(
            SpotReviewHistoryList(
                approved: [ApprovedReviewHistoryItem(historyId: 100, spotId: 7, reviewedAt: "2026-09-08T10:00:00Z")],
                rejected: []
            )
        )
        let controller = makeController()

        await controller.refresh()

        XCTAssertEqual(controller.notice, SpotReviewNotice(historyId: 100, spotId: 7, kind: .approved))
    }

    func test_반려_히스토리가_있으면_반려_스낵바가_뜬다() async {
        reviewHistoryService.historiesResult = .success(
            SpotReviewHistoryList(
                approved: [],
                rejected: [RejectedReviewHistoryItem(
                    historyId: 101, spotId: 7, rejectReason: "LOW_QUALITY",
                    rejectReasonLabel: "사진 상태 불량", rejectDetail: nil, reviewedAt: "2026-09-08T10:00:00Z"
                )]
            )
        )
        let controller = makeController()

        await controller.refresh()

        XCTAssertEqual(controller.notice, SpotReviewNotice(historyId: 101, spotId: 7, kind: .rejected))
    }

    func test_미확인_히스토리가_없으면_스낵바가_뜨지_않는다() async {
        let controller = makeController()

        await controller.refresh()

        XCTAssertNil(controller.notice)
    }

    func test_반려와_승인이_동시에_있으면_반려를_먼저_보여준다() async {
        reviewHistoryService.historiesResult = .success(
            SpotReviewHistoryList(
                approved: [ApprovedReviewHistoryItem(historyId: 100, spotId: 7, reviewedAt: "2026-09-08T10:00:00Z")],
                rejected: [RejectedReviewHistoryItem(
                    historyId: 101, spotId: 8, rejectReason: "LOW_QUALITY",
                    rejectReasonLabel: "사진 상태 불량", rejectDetail: nil, reviewedAt: "2026-09-08T10:00:00Z"
                )]
            )
        )
        let controller = makeController()

        await controller.refresh()

        XCTAssertEqual(controller.notice?.kind, .rejected)
        XCTAssertEqual(controller.notice?.spotId, 8)
    }

    func test_여러건이_동시에_있으면_하나를_닫자마자_다음이_바로_뜬다() async {
        reviewHistoryService.historiesResult = .success(
            SpotReviewHistoryList(
                approved: [ApprovedReviewHistoryItem(historyId: 100, spotId: 7, reviewedAt: "2026-09-08T10:00:00Z")],
                rejected: [RejectedReviewHistoryItem(
                    historyId: 101, spotId: 8, rejectReason: "LOW_QUALITY",
                    rejectReasonLabel: "사진 상태 불량", rejectDetail: nil, reviewedAt: "2026-09-08T10:00:00Z"
                )]
            )
        )
        let controller = makeController()
        await controller.refresh()

        controller.dismissNotice()

        // 서버를 다시 호출하지 않고도(refresh() 재호출 없이) 큐에 있던 다음 건이 바로 뜬다.
        XCTAssertEqual(controller.notice, SpotReviewNotice(historyId: 100, spotId: 7, kind: .approved))
    }

    // MARK: - 소멸 / 확인 처리

    func test_닫기를_누르면_사라지고_확인API가_호출된다() async {
        reviewHistoryService.historiesResult = .success(
            SpotReviewHistoryList(
                approved: [ApprovedReviewHistoryItem(historyId: 100, spotId: 7, reviewedAt: "2026-09-08T10:00:00Z")],
                rejected: []
            )
        )
        let controller = makeController()
        await controller.refresh()

        controller.dismissNotice()
        // markChecked 는 Task { } 로 fire-and-forget 이라 한 틱 양보한다.
        await Task.yield()

        XCTAssertNil(controller.notice)
        XCTAssertEqual(reviewHistoryService.checkedHistoryIds, [100])
    }

    func test_이동_버튼은_대상_스팟을_알려주고_스낵바를_닫는다() async {
        reviewHistoryService.historiesResult = .success(
            SpotReviewHistoryList(
                approved: [ApprovedReviewHistoryItem(historyId: 100, spotId: 7, reviewedAt: "2026-09-08T10:00:00Z")],
                rejected: []
            )
        )
        let controller = makeController()
        await controller.refresh()

        let target = controller.openNoticeTarget()

        XCTAssertEqual(target, 7)
        XCTAssertNil(controller.notice)
    }

    // MARK: - 바텀시트로 인한 일시 숨김

    func test_바텀시트가_뜨면_숨고_닫히면_다시_보인다() async {
        reviewHistoryService.historiesResult = .success(
            SpotReviewHistoryList(
                approved: [ApprovedReviewHistoryItem(historyId: 100, spotId: 7, reviewedAt: "2026-09-08T10:00:00Z")],
                rejected: []
            )
        )
        let controller = makeController()
        await controller.refresh()

        controller.setSpotSheetPresented(true)
        XCTAssertFalse(controller.isNoticeVisible)
        XCTAssertNotNil(controller.notice, "일시 숨김은 소멸이 아니다")

        controller.setSpotSheetPresented(false)
        XCTAssertTrue(controller.isNoticeVisible)
    }

    // MARK: - 저장 탭 인디케이터

    func test_검수중인_스팟이_있으면_인디케이터가_켜진다() async {
        archiveService.mySpotsResponder = { _ in
            .success(MySpotListPage(spots: [.fixture(spotId: 7, status: .pending)], page: 0, hasNext: false))
        }
        let controller = makeController()

        await controller.refresh()

        XCTAssertTrue(controller.showsSavedTabIndicator)
    }

    func test_확인하기_전까지_인디케이터가_유지되고_확인하면_꺼진다() async {
        reviewHistoryService.historiesResult = .success(
            SpotReviewHistoryList(
                approved: [ApprovedReviewHistoryItem(historyId: 100, spotId: 7, reviewedAt: "2026-09-08T10:00:00Z")],
                rejected: []
            )
        )
        let controller = makeController()
        await controller.refresh()

        XCTAssertTrue(controller.showsSavedTabIndicator)

        controller.dismissNotice()
        XCTAssertFalse(controller.showsSavedTabIndicator)
    }

    func test_비로그인이면_아무것도_하지_않는다() async {
        tokenStore.storedToken = nil
        reviewHistoryService.historiesResult = .success(
            SpotReviewHistoryList(
                approved: [ApprovedReviewHistoryItem(historyId: 100, spotId: 7, reviewedAt: "2026-09-08T10:00:00Z")],
                rejected: []
            )
        )
        let controller = makeController()

        await controller.refresh()

        XCTAssertNil(controller.notice)
        XCTAssertFalse(controller.showsSavedTabIndicator)
    }

    private func makeController() -> SpotReviewNoticeController {
        SpotReviewNoticeController(
            archiveService: archiveService,
            reviewHistoryService: reviewHistoryService,
            tokenStore: tokenStore
        )
    }
}
