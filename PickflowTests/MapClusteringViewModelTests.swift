import XCTest
@testable import Pickflow

@MainActor
final class MapClusteringViewModelTests: XCTestCase {
    private var clusteringService: MockClusteringService!
    private var viewModel: MapClusteringViewModel!

    override func setUp() async throws {
        try await super.setUp()
        clusteringService = MockClusteringService()
        viewModel = MapClusteringViewModel(clusteringService: clusteringService, debounceMillis: 0)
    }

    override func tearDown() async throws {
        viewModel = nil
        clusteringService = nil
        try await super.tearDown()
    }

    // MARK: - viewportChanged

    func test_viewportChanged_정상응답_상태가loaded로전환된다() async throws {
        let spot = ClusterableSpot.fixture()
        clusteringService.result = .success([spot])

        await viewModel.viewportChanged(.fixture())

        XCTAssertEqual(viewModel.state, .loaded(spots: [spot]))
    }

    func test_viewportChanged_서비스실패_상태가failed이고에러메시지가설정된다() async throws {
        clusteringService.result = .failure(TestError.failed)

        await viewModel.viewportChanged(.fixture())

        guard case let .failed(message) = viewModel.state else {
            return XCTFail("Expected failed state, got \(viewModel.state)")
        }
        XCTAssertTrue(message.contains("test failure"), "message=\(message)")
    }

    func test_viewportChanged_빈응답_loaded이고spots가비어있다() async throws {
        clusteringService.result = .success([])

        await viewModel.viewportChanged(.fixture())

        XCTAssertEqual(viewModel.state, .loaded(spots: []))
    }

    func test_viewportChanged_호출시_clusteringService가현재viewport와nilTheme로호출된다() async throws {
        let viewport = Viewport.fixture(
            topLeft: Coordinate(latitude: 38.0, longitude: 126.0),
            topRight: Coordinate(latitude: 38.0, longitude: 128.0),
            bottomLeft: Coordinate(latitude: 36.0, longitude: 126.0),
            bottomRight: Coordinate(latitude: 36.0, longitude: 128.0)
        )

        await viewModel.viewportChanged(viewport)

        XCTAssertEqual(clusteringService.requests.count, 1)
        XCTAssertEqual(clusteringService.requests.first?.viewport, viewport)
        XCTAssertEqual(clusteringService.requests.first?.themes, [])
    }

    // MARK: - debounce (1-A)

    func test_viewportChanged_짧은시간내연속호출_마지막호출만fetch된다() async throws {
        // debounceMillis > 0 으로 별도 인스턴스 사용. 처음 3건은 취소되고 마지막 1건만 살아남는다.
        let debouncedVM = MapClusteringViewModel(clusteringService: clusteringService, debounceMillis: 30)
        let viewportA = Viewport.fixture(topLeft: Coordinate(latitude: 1, longitude: 1))
        let viewportB = Viewport.fixture(topLeft: Coordinate(latitude: 2, longitude: 2))
        let viewportC = Viewport.fixture(topLeft: Coordinate(latitude: 3, longitude: 3))
        let viewportD = Viewport.fixture(topLeft: Coordinate(latitude: 4, longitude: 4))

        // async let 은 actor 진입 순서를 보장하지 않아 마지막 생존자가 D가 아닐 수 있다(flaky).
        // 디바운스 윈도(30ms)보다 훨씬 짧은 간격으로 등록 순서를 A→B→C→D 로 고정한다.
        let viewports = [viewportA, viewportB, viewportC, viewportD]
        let tasks = viewports.enumerated().map { index, viewport in
            Task {
                try? await Task.sleep(for: .milliseconds(index * 2))
                await debouncedVM.viewportChanged(viewport)
            }
        }
        for task in tasks { await task.value }

        XCTAssertEqual(clusteringService.requests.count, 1)
        XCTAssertEqual(clusteringService.requests.first?.viewport, viewportD)
    }

    // MARK: - themeChanged

    func test_themeChanged_호출시_마지막viewport와새카테고리로재fetch된다() async throws {
        let viewport = Viewport.fixture()
        await viewModel.viewportChanged(viewport)

        await viewModel.themeChanged([.sunset, .nightView])

        XCTAssertEqual(clusteringService.requests.count, 2)
        XCTAssertEqual(clusteringService.requests.last?.viewport, viewport)
        XCTAssertEqual(clusteringService.requests.last?.themes, [.sunset, .nightView])
    }

    func test_themeChanged_viewport전이없으면_fetch하지않는다() async throws {
        await viewModel.themeChanged([.sunset])

        XCTAssertEqual(clusteringService.requests.count, 0)
    }

    // MARK: - spotMarkerTapped

    func test_spotMarkerTapped_호출시_selectedSpotId가설정된다() async throws {
        await viewModel.spotMarkerTapped(42)

        XCTAssertEqual(viewModel.selectedSpotId, 42)
    }

    // MARK: - my spots

    func test_viewportChanged_호출시_mySpots도fetch되고state에반영된다() async throws {
        let mySpot = MySpot.fixture()
        clusteringService.mySpotsResult = .success([mySpot])

        await viewModel.viewportChanged(.fixture())

        XCTAssertEqual(clusteringService.mySpotsRequests.count, 1)
        XCTAssertEqual(viewModel.mySpots, [mySpot])
    }

    func test_viewportChanged_viewport호출실패시_state는failed이고_mySpots는비어있다() async throws {
        // viewport는 curation/mySpot을 단일 엔드포인트에서 함께 받아오므로,
        // 호출이 실패하면 둘 다 비어있는 것이 새 동작 시멘틱.
        clusteringService.result = .failure(TestError.failed)
        clusteringService.mySpotsResult = .success([MySpot.fixture()])

        await viewModel.viewportChanged(.fixture())

        guard case .failed = viewModel.state else {
            return XCTFail("Expected failed state, got \(viewModel.state)")
        }
        XCTAssertEqual(viewModel.mySpots, [])
    }

    // MARK: - mapBackgroundTapped

    func test_mapBackgroundTapped_호출시_selectedSpotId가nil로해제된다() async throws {
        await viewModel.spotMarkerTapped(42)
        XCTAssertEqual(viewModel.selectedSpotId, 42)

        await viewModel.mapBackgroundTapped()

        XCTAssertNil(viewModel.selectedSpotId)
    }
}
