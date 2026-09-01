import XCTest
@testable import Pickflow

final class NewFeatureGuideStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: UserDefaultsNewFeatureGuideStore!
    private var remoteConfigProvider: StubNewFeatureRemoteConfigProvider!
    private let startAt: Int64 = 1_755_831_600_000
    private let endAt: Int64 = 1_757_041_200_000
    private lazy var startDate = Date(timeIntervalSince1970: TimeInterval(startAt) / 1000)
    private lazy var endDate = Date(timeIntervalSince1970: TimeInterval(endAt) / 1000)

    override func setUp() {
        super.setUp()
        suiteName = "NewFeatureGuideStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        remoteConfigProvider = StubNewFeatureRemoteConfigProvider(result: .success(.fixture(
            features: [
                .fixture(key: "v2_update_modal", startAt: startAt, endAt: endAt),
                .fixture(key: "spot_open_guide", startAt: startAt, endAt: endAt),
                .fixture(key: "home_new_badge", startAt: startAt, endAt: endAt),
            ]
        )))
        store = UserDefaultsNewFeatureGuideStore(
            defaults: defaults,
            appVersionProvider: { "2.0.0" },
            remoteConfigProvider: remoteConfigProvider
        )
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        store = nil
        remoteConfigProvider = nil
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func test_refreshFeatureConfig_원격설정을저장하고_feature를노출한다() async {
        XCTAssertFalse(store.shouldShowV2UpdateModal(now: startDate))
        XCTAssertFalse(store.shouldShowSpotOpenGuide(userKey: "user-a", now: startDate))
        XCTAssertFalse(store.shouldShowNewThemeIndicators(now: startDate))

        await store.refreshFeatureConfig()

        XCTAssertTrue(store.shouldShowV2UpdateModal(now: startDate))
        XCTAssertTrue(store.shouldShowSpotOpenGuide(userKey: "user-a", now: startDate))
        XCTAssertTrue(store.shouldShowNewThemeIndicators(now: startDate))
    }

    func test_런칭일기준_feature는_startAt이상_endAt미만일때만노출한다() async {
        remoteConfigProvider.result = .success(.fixture(
            features: [
                .fixture(key: "v2_update_modal", startAt: startAt, endAt: endAt),
                .fixture(key: "spot_open_guide", startAt: startAt, endAt: endAt),
                .fixture(key: "home_new_badge", startAt: startAt, endAt: endAt),
            ]
        ))
        await store.refreshFeatureConfig()

        XCTAssertTrue(store.shouldShowV2UpdateModal(now: startDate))
        XCTAssertTrue(store.shouldShowSpotOpenGuide(userKey: "user-a", now: startDate))
        XCTAssertTrue(store.shouldShowNewThemeIndicators(now: startDate))
        XCTAssertFalse(store.shouldShowV2UpdateModal(now: endDate))
        XCTAssertFalse(store.shouldShowSpotOpenGuide(userKey: "user-a", now: endDate))
        XCTAssertFalse(store.shouldShowNewThemeIndicators(now: endDate))
    }

    func test_V2업데이트모달확인후_재노출하지않는다() async {
        await store.refreshFeatureConfig()
        XCTAssertTrue(store.shouldShowV2UpdateModal(now: startDate))

        store.markV2UpdateModalSeen()

        XCTAssertFalse(store.shouldShowV2UpdateModal(now: startDate))
    }

    func test_스팟오픈안내는_유저키별로_확인여부를분리한다() async {
        await store.refreshFeatureConfig()
        XCTAssertTrue(store.shouldShowSpotOpenGuide(userKey: "user-a", now: startDate))
        XCTAssertTrue(store.shouldShowSpotOpenGuide(userKey: "user-b", now: startDate))

        store.markSpotOpenGuideSeen(userKey: "user-a")

        XCTAssertFalse(store.shouldShowSpotOpenGuide(userKey: "user-a", now: startDate))
        XCTAssertTrue(store.shouldShowSpotOpenGuide(userKey: "user-b", now: startDate))
    }

    func test_유저별기준_feature는_최초평가시각을저장하고_durationDays동안노출한다() async {
        remoteConfigProvider.result = .success(.fixture(
            features: [
                .fixture(key: "home_new_badge", startAt: nil, endAt: nil, durationDays: 14),
            ]
        ))
        await store.refreshFeatureConfig()
        XCTAssertTrue(store.shouldShowNewThemeIndicators(now: startDate))

        remoteConfigProvider.result = .success(.fixture(
            features: [
                .fixture(key: "home_new_badge", startAt: nil, endAt: nil, durationDays: 14),
            ]
        ))
        await store.refreshFeatureConfig()

        XCTAssertFalse(store.shouldShowNewThemeIndicators(now: startDate.addingTimeInterval(14 * 24 * 60 * 60)))
    }

    func test_remoteConfigFetch실패시_마지막캐시로판정한다() async {
        await store.refreshFeatureConfig()
        XCTAssertTrue(store.shouldShowNewThemeIndicators(now: startDate))

        remoteConfigProvider.result = .failure(TestError.failed)
        await store.refreshFeatureConfig()

        XCTAssertTrue(store.shouldShowNewThemeIndicators(now: startDate))
    }
}

private extension NewFeatureRemoteConfig {
    static func fixture(
        features: [NewFeatureRemoteConfigFeature]
    ) -> NewFeatureRemoteConfig {
        NewFeatureRemoteConfig(features: features)
    }
}

private extension NewFeatureRemoteConfigFeature {
    static func fixture(
        key: String,
        startAt: Int64?,
        endAt: Int64?,
        durationDays: Int? = 14
    ) -> NewFeatureRemoteConfigFeature {
        NewFeatureRemoteConfigFeature(
            key: key,
            startAt: startAt,
            endAt: endAt,
            durationDays: durationDays
        )
    }
}
