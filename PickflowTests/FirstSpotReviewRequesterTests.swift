import XCTest
@testable import Pickflow

@MainActor
final class FirstSpotReviewRequesterTests: XCTestCase {
    private var store: FakeReviewRequestStore!
    private var service: SpyReviewRequestService!
    private var analytics: SpyAnalyticsLogger!
    private var requester: FirstSpotReviewRequester!

    override func setUp() async throws {
        try await super.setUp()
        store = FakeReviewRequestStore()
        service = SpyReviewRequestService()
        analytics = SpyAnalyticsLogger()
        requester = makeRequester()
    }

    override func tearDown() async throws {
        requester = nil
        analytics = nil
        service = nil
        store = nil
        try await super.tearDown()
    }

    // MARK: - 발동 성공 경로

    func test_requestReviewAfterDelay_활성scene있으면_평점요청발동하고_1회플래그와_노출로그를남긴다() async {
        service.requestReviewResult = true

        await requester.requestReviewAfterDelay()

        XCTAssertEqual(service.requestReviewCallCount, 1)
        XCTAssertEqual(store.markCallCount, 1)
        XCTAssertTrue(store.hasRequestedValue)
        XCTAssertEqual(analytics.loggedEventNames, ["app_review_system_prompt_shown"])
    }

    // MARK: - 발동 실패(활성 scene 없음) 경로

    func test_requestReviewAfterDelay_활성scene없으면_플래그를남기지않고_로그도남기지않는다() async {
        service.requestReviewResult = false

        await requester.requestReviewAfterDelay()

        XCTAssertEqual(service.requestReviewCallCount, 1)
        XCTAssertEqual(store.markCallCount, 0)
        XCTAssertFalse(store.hasRequestedValue)
        XCTAssertTrue(analytics.loggedEventNames.isEmpty)
    }

    // MARK: - 1회 제어(중복 노출 방지)

    func test_spotRegistrationDidComplete_이미노출이력이있으면_요청을발동하지않는다() {
        store.hasRequestedValue = true

        requester.spotRegistrationDidComplete()

        XCTAssertEqual(service.requestReviewCallCount, 0)
        XCTAssertTrue(analytics.loggedEventNames.isEmpty)
    }

    func test_최초발동이후_두번째등록완료에서는_다시발동하지않는다() async {
        // 1번째 등록 완료: 실제 발동되어 플래그가 저장된다.
        await requester.requestReviewAfterDelay()
        XCTAssertEqual(service.requestReviewCallCount, 1)
        XCTAssertTrue(store.hasRequestedValue)

        // 2번째 등록 완료: guard 에서 걸려 추가 발동이 없어야 한다.
        requester.spotRegistrationDidComplete()
        XCTAssertEqual(service.requestReviewCallCount, 1)
        XCTAssertEqual(analytics.loggedEventNames.count, 1)
    }

    // MARK: - Helpers

    private func makeRequester() -> FirstSpotReviewRequester {
        FirstSpotReviewRequester(
            store: store,
            service: service,
            analyticsLogger: analytics,
            presentDelay: 0
        )
    }
}
