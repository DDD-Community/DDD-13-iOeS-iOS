import XCTest
@testable import Pickflow

final class NewFeatureGuideStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: UserDefaultsNewFeatureGuideStore!
    private var remoteConfigProvider: StubNewFeatureRemoteConfigProvider!
    private let startAt: Int64 = 1_755_831_600_000
    private let endAt: Int64 = 1_757_041_200_000

    override func setUp() {
        super.setUp()
        suiteName = "NewFeatureGuideStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        remoteConfigProvider = StubNewFeatureRemoteConfigProvider(result: .success(.fixture(
            serverTime: startAt,
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
        XCTAssertFalse(store.shouldShowV2UpdateModal(now: Date()))
        XCTAssertFalse(store.shouldShowSpotOpenGuide(userKey: "user-a", now: Date()))
        XCTAssertFalse(store.shouldShowNewThemeIndicators())

        await store.refreshFeatureConfig()

        XCTAssertTrue(store.shouldShowV2UpdateModal(now: Date()))
        XCTAssertTrue(store.shouldShowSpotOpenGuide(userKey: "user-a", now: Date()))
        XCTAssertTrue(store.shouldShowNewThemeIndicators())
    }

    func test_런칭일기준_feature는_startAt이상_endAt미만일때만노출한다() async {
        remoteConfigProvider.result = .success(.fixture(
            serverTime: endAt,
            features: [
                .fixture(key: "v2_update_modal", startAt: startAt, endAt: endAt),
                .fixture(key: "spot_open_guide", startAt: startAt, endAt: endAt),
                .fixture(key: "home_new_badge", startAt: startAt, endAt: endAt),
            ]
        ))
        await store.refreshFeatureConfig()

        XCTAssertFalse(store.shouldShowV2UpdateModal(now: Date()))
        XCTAssertFalse(store.shouldShowSpotOpenGuide(userKey: "user-a", now: Date()))
        XCTAssertFalse(store.shouldShowNewThemeIndicators())
    }

    func test_V2업데이트모달확인후_재노출하지않는다() async {
        await store.refreshFeatureConfig()
        XCTAssertTrue(store.shouldShowV2UpdateModal(now: Date()))

        store.markV2UpdateModalSeen()

        XCTAssertFalse(store.shouldShowV2UpdateModal(now: Date()))
    }

    func test_스팟오픈안내는_유저키별로_확인여부를분리한다() async {
        await store.refreshFeatureConfig()
        XCTAssertTrue(store.shouldShowSpotOpenGuide(userKey: "user-a", now: Date()))
        XCTAssertTrue(store.shouldShowSpotOpenGuide(userKey: "user-b", now: Date()))

        store.markSpotOpenGuideSeen(userKey: "user-a")

        XCTAssertFalse(store.shouldShowSpotOpenGuide(userKey: "user-a", now: Date()))
        XCTAssertTrue(store.shouldShowSpotOpenGuide(userKey: "user-b", now: Date()))
    }

    func test_유저별기준_feature는_최초평가serverTime을저장하고_durationDays동안노출한다() async {
        remoteConfigProvider.result = .success(.fixture(
            serverTime: startAt,
            features: [
                .fixture(key: "home_new_badge", startAt: nil, endAt: nil, durationDays: 14),
            ]
        ))
        await store.refreshFeatureConfig()
        XCTAssertTrue(store.shouldShowNewThemeIndicators())

        remoteConfigProvider.result = .success(.fixture(
            serverTime: startAt + 14 * 24 * 60 * 60 * 1000,
            features: [
                .fixture(key: "home_new_badge", startAt: nil, endAt: nil, durationDays: 14),
            ]
        ))
        await store.refreshFeatureConfig()

        XCTAssertFalse(store.shouldShowNewThemeIndicators())
    }

    func test_remoteConfigFetch실패시_마지막캐시로판정한다() async {
        await store.refreshFeatureConfig()
        XCTAssertTrue(store.shouldShowNewThemeIndicators())

        remoteConfigProvider.result = .failure(TestError.failed)
        await store.refreshFeatureConfig()

        XCTAssertTrue(store.shouldShowNewThemeIndicators())
    }
}

private extension NewFeatureRemoteConfig {
    static func fixture(
        serverTime: Int64,
        features: [NewFeatureRemoteConfigFeature]
    ) -> NewFeatureRemoteConfig {
        NewFeatureRemoteConfig(serverTime: serverTime, features: features)
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
