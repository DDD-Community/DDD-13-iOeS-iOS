import XCTest
@testable import Pickflow

final class ReviewRequestStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: UserDefaultsReviewRequestStore!

    override func setUp() {
        super.setUp()
        suiteName = "ReviewRequestStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        store = UserDefaultsReviewRequestStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        store = nil
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func test_초기상태_hasRequestedReview는false이다() {
        XCTAssertFalse(store.hasRequestedReview())
    }

    func test_markReviewRequested_호출후_hasRequestedReview가true가된다() {
        store.markReviewRequested()
        XCTAssertTrue(store.hasRequestedReview())
    }

    func test_markReviewRequested_상태는_새인스턴스에서도_유지된다() {
        store.markReviewRequested()

        let reloaded = UserDefaultsReviewRequestStore(defaults: defaults)
        XCTAssertTrue(reloaded.hasRequestedReview())
    }
}
