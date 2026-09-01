import XCTest
@testable import Pickflow

@MainActor
final class RegionSelectionStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var regionService: MockRegionService!

    override func setUp() {
        super.setUp()
        suiteName = "RegionSelectionStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        regionService = MockRegionService()
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        regionService = nil
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - loadIfNeeded

    func test_loadIfNeeded_정상응답시_regions와_저장된값없으면첫번째지역이선택된다() async {
        let store = RegionSelectionStore(regionService: regionService, defaults: defaults)

        await store.loadIfNeeded()

        XCTAssertEqual(store.regions, Region.fallbackRegions)
        XCTAssertEqual(store.selectedRegion, Region.fallbackRegions.first)
    }

    func test_loadIfNeeded_API실패시_폴백지역목록으로대체된다() async {
        regionService.error = TestError.failed
        let store = RegionSelectionStore(regionService: regionService, defaults: defaults)

        await store.loadIfNeeded()

        XCTAssertEqual(store.regions, Region.fallbackRegions)
        XCTAssertEqual(store.selectedRegion, Region.fallbackRegions.first)
    }

    func test_loadIfNeeded_API가빈배열반환시_폴백지역목록으로대체된다() async {
        regionService.regions = []
        let store = RegionSelectionStore(regionService: regionService, defaults: defaults)

        await store.loadIfNeeded()

        XCTAssertEqual(store.regions, Region.fallbackRegions)
    }

    func test_loadIfNeeded_짧은시간내연속호출시_API는한번만호출된다() async {
        let store = RegionSelectionStore(regionService: regionService, defaults: defaults)

        async let first: () = store.loadIfNeeded()
        async let second: () = store.loadIfNeeded()
        _ = await (first, second)

        XCTAssertEqual(regionService.fetchCallCount, 1)
    }

    // MARK: - select

    func test_select_호출시_selectedRegion이변경된다() async {
        let store = RegionSelectionStore(regionService: regionService, defaults: defaults)
        await store.loadIfNeeded()
        let seoul = Region.fallbackRegions[1]

        store.select(seoul)

        XCTAssertEqual(store.selectedRegion, seoul)
    }

    func test_select_로저장한값은_새인스턴스의loadIfNeeded에서복원된다() async {
        let firstStore = RegionSelectionStore(regionService: regionService, defaults: defaults)
        await firstStore.loadIfNeeded()
        let seoul = Region.fallbackRegions[1]
        firstStore.select(seoul)

        let secondStore = RegionSelectionStore(regionService: regionService, defaults: defaults)
        await secondStore.loadIfNeeded()

        XCTAssertEqual(secondStore.selectedRegion, seoul)
    }

    func test_저장된지역ID가새로로드된목록에없으면_첫번째지역이선택된다() async {
        // 이전 세션에서 id=2(서울)를 선택해 저장해둔 상태를 시뮬레이션.
        defaults.set(2, forKey: "regionSelection.selectedRegionId")
        regionService.regions = [Region(
            id: 99,
            name: "부산",
            southWestLatitude: 0, southWestLongitude: 0,
            northEastLatitude: 0, northEastLongitude: 0
        )]
        let store = RegionSelectionStore(regionService: regionService, defaults: defaults)

        await store.loadIfNeeded()

        XCTAssertEqual(store.selectedRegion?.id, 99)
    }
}
