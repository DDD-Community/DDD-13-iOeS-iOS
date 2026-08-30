import XCTest
@testable import Pickflow

/// PV-40 — 검수 결과 스낵바와 저장 탭 인디케이터.
@MainActor
final class SpotReviewNoticeTests: XCTestCase {
    private var archiveService: MockArchiveService!
    private var store: InMemoryReviewSeenStore!
    private var tokenStore: MockTokenStore!

    override func setUp() async throws {
        try await super.setUp()
        archiveService = MockArchiveService()
        store = InMemoryReviewSeenStore()
        tokenStore = MockTokenStore()
        tokenStore.storedToken = AuthToken(accessToken: "t", refreshToken: "r")
    }

    override func tearDown() async throws {
        tokenStore = nil
        store = nil
        archiveService = nil
        try await super.tearDown()
    }

    // MARK: - 결과 감지

    func test_검수중이던_스팟이_승인되면_승인_스낵바가_뜬다() async {
        store.seen = [7: .pending]
        let controller = makeController(spots: [.fixture(spotId: 7, status: .published)])

        await controller.refresh()

        XCTAssertEqual(controller.notice, SpotReviewNotice(spotId: 7, kind: .approved))
    }

    func test_검수중이던_스팟이_반려되면_반려_스낵바가_뜬다() async {
        store.seen = [7: .reReviewPending]
        let controller = makeController(spots: [.fixture(spotId: 7, status: .rejected)])

        await controller.refresh()

        XCTAssertEqual(controller.notice, SpotReviewNotice(spotId: 7, kind: .rejected))
    }

    func test_아직_검수중이면_스낵바가_뜨지_않는다() async {
        store.seen = [7: .pending]
        let controller = makeController(spots: [.fixture(spotId: 7, status: .pending)])

        await controller.refresh()

        XCTAssertNil(controller.notice)
    }

    func test_이미_본_결과는_다시_뜨지_않는다() async {
        store.seen = [7: .published]
        let controller = makeController(spots: [.fixture(spotId: 7, status: .published)])

        await controller.refresh()

        XCTAssertNil(controller.notice)
    }

    func test_검수를_거치지_않은_상태변화는_결과로_보지_않는다() async {
        // 나만보기 → 공개 는 검수 결과가 아니라 유저가 직접 되돌린 경우다.
        store.seen = [7: .draft]
        let controller = makeController(spots: [.fixture(spotId: 7, status: .published)])

        await controller.refresh()

        XCTAssertNil(controller.notice)
    }

    // MARK: - 소멸

    func test_닫기를_누르면_사라지고_다시_뜨지_않는다() async {
        store.seen = [7: .pending]
        let controller = makeController(spots: [.fixture(spotId: 7, status: .published)])
        await controller.refresh()

        controller.dismissNotice()

        XCTAssertNil(controller.notice)
        await controller.refresh()
        XCTAssertNil(controller.notice)
    }

    func test_이동_버튼은_대상_스팟을_알려주고_스낵바를_닫는다() async {
        store.seen = [7: .pending]
        let controller = makeController(spots: [.fixture(spotId: 7, status: .published)])
        await controller.refresh()

        let target = controller.openNoticeTarget()

        XCTAssertEqual(target, 7)
        XCTAssertNil(controller.notice)
    }

    // MARK: - 바텀시트로 인한 일시 숨김

    func test_바텀시트가_뜨면_숨고_닫히면_다시_보인다() async {
        store.seen = [7: .pending]
        let controller = makeController(spots: [.fixture(spotId: 7, status: .published)])
        await controller.refresh()

        controller.setSpotSheetPresented(true)
        XCTAssertFalse(controller.isNoticeVisible)
        XCTAssertNotNil(controller.notice, "일시 숨김은 소멸이 아니다")

        controller.setSpotSheetPresented(false)
        XCTAssertTrue(controller.isNoticeVisible)
    }

    // MARK: - 저장 탭 인디케이터

    func test_검수중인_스팟이_있으면_인디케이터가_켜진다() async {
        let controller = makeController(spots: [.fixture(spotId: 7, status: .pending)])

        await controller.refresh()

        XCTAssertTrue(controller.showsSavedTabIndicator)
    }

    func test_결과를_확인하기_전까지_인디케이터가_유지된다() async {
        store.seen = [7: .pending]
        let controller = makeController(spots: [.fixture(spotId: 7, status: .published)])
        await controller.refresh()

        XCTAssertTrue(controller.showsSavedTabIndicator)

        controller.dismissNotice()
        XCTAssertFalse(controller.showsSavedTabIndicator)
    }

    func test_비로그인이면_아무것도_하지_않는다() async {
        tokenStore.storedToken = nil
        let controller = makeController(spots: [.fixture(spotId: 7, status: .pending)])

        await controller.refresh()

        XCTAssertNil(controller.notice)
        XCTAssertFalse(controller.showsSavedTabIndicator)
    }

    private func makeController(spots: [MySpotListItem]) -> SpotReviewNoticeController {
        archiveService.mySpotsResponder = { _ in
            .success(MySpotListPage(spots: spots, page: 0, hasNext: false))
        }
        return SpotReviewNoticeController(
            archiveService: archiveService,
            tokenStore: tokenStore,
            store: store
        )
    }
}

final class InMemoryReviewSeenStore: SpotReviewSeenStoring, @unchecked Sendable {
    var seen: [Int64: MySpotStatus] = [:]
    func lastSeenStatuses() -> [Int64: MySpotStatus] { seen }
    func save(_ statuses: [Int64: MySpotStatus]) { seen = statuses }
}
