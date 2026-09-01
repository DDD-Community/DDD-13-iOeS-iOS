import XCTest
@testable import Pickflow

@MainActor
final class SpotLocationDetailViewModelTests: XCTestCase {
    private var addressService: MockAddressService!
    private var locationService: SpotSearchMockLocationService!
    private var originalAddress: Address!

    override func setUp() async throws {
        try await super.setUp()
        addressService = MockAddressService()
        locationService = SpotSearchMockLocationService()
        originalAddress = Address.fixture(
            coordinate: Coordinate(latitude: 37.5665, longitude: 126.9780)
        )
    }

    override func tearDown() async throws {
        addressService = nil
        locationService = nil
        originalAddress = nil
        try await super.tearDown()
    }

    private func makeSUT() -> SpotLocationDetailViewModel {
        SpotLocationDetailViewModel(
            originalAddress: originalAddress,
            addressService: addressService,
            locationService: locationService
        )
    }

    func test_init_currentCoordinate는_originalAddress좌표로_세팅된다() {
        let sut = makeSUT()
        XCTAssertEqual(sut.currentCoordinate, Coordinate(latitude: 37.5665, longitude: 126.9780))
    }

    func test_confirm_좌표동일시_reverseGeocode호출없이_원본Address콜백() async {
        let sut = makeSUT()
        var confirmedAddress: Address?
        sut.onConfirm = { confirmedAddress = $0 }

        await sut.confirm(markerCoordinate: Coordinate(latitude: 37.5665, longitude: 126.9780))

        XCTAssertEqual(addressService.reverseGeocodeCallCount, 0)
        XCTAssertEqual(confirmedAddress, originalAddress)
    }

    func test_confirm_좌표변경시_reverseGeocode호출하고_반환Address콜백() async {
        let newAddress = Address.fixture(
            id: "reverse-1",
            name: nil,
            fullAddress: "서울 강남구 테헤란로",
            coordinate: Coordinate(latitude: 37.5000, longitude: 127.0500)
        )
        addressService.reverseGeocodeResult = .success(newAddress)
        let sut = makeSUT()
        var confirmedAddress: Address?
        sut.onConfirm = { confirmedAddress = $0 }

        await sut.confirm(markerCoordinate: Coordinate(latitude: 37.5000, longitude: 127.0500))

        XCTAssertEqual(addressService.reverseGeocodeCallCount, 1)
        XCTAssertEqual(addressService.reverseGeocodeCoordinates.first,
                       Coordinate(latitude: 37.5000, longitude: 127.0500))
        XCTAssertEqual(confirmedAddress, newAddress)
    }

    func test_confirm_reverseGeocode실패시_좌표만교체한_fallbackAddress콜백() async {
        addressService.reverseGeocodeResult = .failure(TestError.failed)
        let sut = makeSUT()
        var confirmedAddress: Address?
        sut.onConfirm = { confirmedAddress = $0 }

        let newCoordinate = Coordinate(latitude: 37.5000, longitude: 127.0500)
        await sut.confirm(markerCoordinate: newCoordinate)

        XCTAssertEqual(addressService.reverseGeocodeCallCount, 1)
        XCTAssertEqual(confirmedAddress?.coordinate, newCoordinate)
        XCTAssertEqual(confirmedAddress?.name, originalAddress.name)
        XCTAssertEqual(confirmedAddress?.fullAddress, originalAddress.fullAddress)
    }

    func test_confirm_종료후_isConfirming은_false() async {
        addressService.reverseGeocodeResult = .success(.fixture())
        let sut = makeSUT()

        await sut.confirm(markerCoordinate: Coordinate(latitude: 37.5000, longitude: 127.0500))

        XCTAssertFalse(sut.isConfirming)
    }

    func test_moveToCurrentLocation_권한허용시_userLocation과cameraMoveRequest설정() async {
        locationService.status = .authorizedWhenInUse
        locationService.result = .success(Coordinate(latitude: 37.5000, longitude: 127.0500))
        let sut = makeSUT()

        await sut.moveToCurrentLocation()

        XCTAssertEqual(sut.userLocation, Coordinate(latitude: 37.5000, longitude: 127.0500))
        guard case let .point(coordinate, _, _) = sut.cameraMoveRequest?.target else {
            return XCTFail("Expected point target")
        }
        XCTAssertEqual(coordinate, Coordinate(latitude: 37.5000, longitude: 127.0500))
    }

    func test_moveToCurrentLocation_권한거부시_alert노출하고_위치갱신없음() async {
        locationService.status = .denied
        let sut = makeSUT()

        await sut.moveToCurrentLocation()

        XCTAssertTrue(sut.showLocationPermissionAlert)
        XCTAssertNil(sut.userLocation)
        XCTAssertNil(sut.cameraMoveRequest)
    }

    func test_moveToCurrentLocation_권한제한시_alert노출하고_위치갱신없음() async {
        locationService.status = .restricted
        let sut = makeSUT()

        await sut.moveToCurrentLocation()

        XCTAssertTrue(sut.showLocationPermissionAlert)
        XCTAssertNil(sut.userLocation)
    }
}
