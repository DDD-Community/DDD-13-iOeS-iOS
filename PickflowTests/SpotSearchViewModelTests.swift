import XCTest
@testable import Pickflow

@MainActor
final class SpotSearchViewModelTests: XCTestCase {
    private var addressService: MockAddressService!
    private var locationService: SpotSearchMockLocationService!
    private var viewModel: SpotSearchViewModel!

    override func setUp() async throws {
        try await super.setUp()
        addressService = MockAddressService()
        locationService = SpotSearchMockLocationService()
        viewModel = SpotSearchViewModel(
            addressService: addressService,
            locationService: locationService
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        locationService = nil
        addressService = nil
        try await super.tearDown()
    }

    func test_init_초기상태는idle이고검색어는비어있다() {
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(viewModel.searchQuery, "")
    }

    func test_search_검색어가비어있으면_idle로전환되고API를호출하지않는다() async {
        viewModel.searchQuery = "   "
        await viewModel.search()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(addressService.callCount, 0)
    }

    func test_search_정상응답결과있음_loaded로전환되고trim된검색어로호출한다() async {
        viewModel.searchQuery = "  한강공원 "

        await viewModel.search()

        XCTAssertEqual(addressService.queries, ["한강공원"])
        XCTAssertEqual(viewModel.state, .loaded([.fixture()]))
    }

    func test_search_정상응답빈배열_empty로전환된다() async {
        addressService.result = .success([])
        viewModel.searchQuery = "한강공원"

        await viewModel.search()

        XCTAssertEqual(viewModel.state, .empty)
    }

    func test_search_API실패_failed로전환되고에러메시지가포함된다() async {
        addressService.result = .failure(TestError.failed)
        viewModel.searchQuery = "한강공원"

        await viewModel.search()

        guard case let .failed(message) = viewModel.state else {
            return XCTFail("Expected failed state")
        }
        XCTAssertTrue(message.contains("test failure"))
    }

    func test_selectAddress_주소를전달하면_onSelectAddress가호출된다() {
        let address = Address.fixture()
        var selectedAddress: Address?
        viewModel.onSelectAddress = { selectedAddress = $0 }

        viewModel.selectAddress(address)

        XCTAssertEqual(selectedAddress, address)
    }

    func test_distanceText_현재위치와주소좌표가있으면_km단위로표시한다() async {
        viewModel.searchQuery = "한강공원"
        await viewModel.search()
        let address = Address.fixture(coordinate: Coordinate(latitude: 37.5209, longitude: 127.0116))

        XCTAssertEqual(viewModel.distanceText(for: address), "2.5km")
    }

    func test_distanceText_주소좌표가없으면_nil을반환한다() {
        let address = Address.fixture(coordinate: nil)

        XCTAssertNil(viewModel.distanceText(for: address))
    }

    func test_distanceText_현재위치조회실패면_nil을반환한다() async {
        locationService.result = .failure(TestError.failed)
        viewModel.searchQuery = "한강공원"
        await viewModel.search()

        XCTAssertNil(viewModel.distanceText(for: .fixture()))
    }

    func test_distanceText_위치권한이거부면_nil을반환한다() async {
        locationService.status = .denied
        viewModel.searchQuery = "한강공원"
        await viewModel.search()

        XCTAssertNil(viewModel.distanceText(for: .fixture()))
    }

    func test_distanceText_위치권한이미결정이면_nil을반환한다() async {
        locationService.status = .notDetermined
        viewModel.searchQuery = "한강공원"
        await viewModel.search()

        XCTAssertNil(viewModel.distanceText(for: .fixture()))
    }

    func test_distanceText_위치권한이제한이면_nil을반환한다() async {
        locationService.status = .restricted
        viewModel.searchQuery = "한강공원"
        await viewModel.search()

        XCTAssertNil(viewModel.distanceText(for: .fixture()))
    }
}
