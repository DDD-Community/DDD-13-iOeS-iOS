import XCTest
@testable import Pickflow

/// V2 업데이트 안내 모달의 노출 정책.
@MainActor
final class V2UpdateNoticeTests: XCTestCase {
    private var store: InMemoryV2NoticeStore!

    private let endDate = Date(timeIntervalSince1970: 2_000_000)

    override func setUp() async throws {
        try await super.setUp()
        store = InMemoryV2NoticeStore()
    }

    override func tearDown() async throws {
        store = nil
        try await super.tearDown()
    }

    func test_노출기간_안이고_아직_확인하지_않았으면_뜬다() {
        let controller = makeController(now: endDate.addingTimeInterval(-1))

        controller.checkOnLaunch()

        XCTAssertTrue(controller.isPresented)
    }

    func test_이미_확인했으면_기간_안이어도_뜨지_않는다() {
        store.acknowledge()
        let controller = makeController(now: endDate.addingTimeInterval(-1))

        controller.checkOnLaunch()

        XCTAssertFalse(controller.isPresented)
    }

    func test_노출기간이_지나면_확인하지_않았어도_뜨지_않는다() {
        let controller = makeController(now: endDate.addingTimeInterval(1))

        controller.checkOnLaunch()

        XCTAssertFalse(controller.isPresented)
    }

    func test_종료시각_정각에는_뜨지_않는다() {
        let controller = makeController(now: endDate)

        controller.checkOnLaunch()

        XCTAssertFalse(controller.isPresented)
    }

    func test_확인했어요를_누르면_닫히고_다음_실행에는_뜨지_않는다() {
        let controller = makeController(now: endDate.addingTimeInterval(-1))
        controller.checkOnLaunch()

        controller.acknowledge()

        XCTAssertFalse(controller.isPresented)
        XCTAssertTrue(store.hasAcknowledged)

        let relaunched = makeController(now: endDate.addingTimeInterval(-1))
        relaunched.checkOnLaunch()
        XCTAssertFalse(relaunched.isPresented)
    }

    func test_확인하지_않고_앱을_다시_켜면_또_뜬다() {
        let controller = makeController(now: endDate.addingTimeInterval(-1))
        controller.checkOnLaunch()

        // 확인 없이 종료한 셈
        let relaunched = makeController(now: endDate.addingTimeInterval(-1))
        relaunched.checkOnLaunch()

        XCTAssertTrue(relaunched.isPresented)
    }

    private func makeController(now: Date) -> V2UpdateNoticeController {
        V2UpdateNoticeController(
            store: store,
            endDate: endDate,
            clock: { now }
        )
    }
}

final class InMemoryV2NoticeStore: V2NoticeAcknowledging, @unchecked Sendable {
    private(set) var hasAcknowledged = false
    func acknowledge() { hasAcknowledged = true }
}
