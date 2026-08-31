import XCTest
@testable import Pickflow

final class NewFeatureGuideStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: UserDefaultsNewFeatureGuideStore!
    private let start = Date(timeIntervalSince1970: 1_788_115_600)

    override func setUp() {
        super.setUp()
        suiteName = "NewFeatureGuideStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        store = UserDefaultsNewFeatureGuideStore(
            defaults: defaults,
            appVersionProvider: { "2.0.0" }
        )
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        store = nil
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func test_최초14일동안_V2업데이트모달을노출한다() {
        XCTAssertTrue(store.shouldShowV2UpdateModal(now: start))
        XCTAssertTrue(store.shouldShowV2UpdateModal(now: start.addingTimeInterval(14 * 24 * 60 * 60 - 1)))
    }

    func test_14일이후_V2업데이트모달을노출하지않는다() {
        XCTAssertTrue(store.shouldShowV2UpdateModal(now: start))

        XCTAssertFalse(store.shouldShowV2UpdateModal(now: start.addingTimeInterval(14 * 24 * 60 * 60)))
    }

    func test_V2업데이트모달확인후_재노출하지않는다() {
        XCTAssertTrue(store.shouldShowV2UpdateModal(now: start))

        store.markV2UpdateModalSeen()

        XCTAssertFalse(store.shouldShowV2UpdateModal(now: start))
    }

    func test_스팟오픈안내는_유저키별로_확인여부를분리한다() {
        XCTAssertTrue(store.shouldShowSpotOpenGuide(userKey: "user-a", now: start))
        XCTAssertTrue(store.shouldShowSpotOpenGuide(userKey: "user-b", now: start))

        store.markSpotOpenGuideSeen(userKey: "user-a")

        XCTAssertFalse(store.shouldShowSpotOpenGuide(userKey: "user-a", now: start))
        XCTAssertTrue(store.shouldShowSpotOpenGuide(userKey: "user-b", now: start))
    }

    func test_신규카테고리인디케이터는_14일동안만노출한다() {
        XCTAssertTrue(store.shouldShowNewThemeIndicators(now: start))
        XCTAssertFalse(store.shouldShowNewThemeIndicators(now: start.addingTimeInterval(14 * 24 * 60 * 60)))
    }
}
