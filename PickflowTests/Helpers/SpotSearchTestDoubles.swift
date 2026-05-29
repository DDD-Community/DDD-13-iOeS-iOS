import CoreLocation
import Foundation
@testable import Pickflow

final class MockAddressService: AddressServiceProtocol, @unchecked Sendable {
    var result: Result<[Address], any Error> = .success([.fixture()])
    var reverseGeocodeResult: Result<Address, any Error> = .failure(TestError.failed)
    private(set) var callCount = 0
    private(set) var queries: [String] = []
    private(set) var reverseGeocodeCallCount = 0
    private(set) var reverseGeocodeCoordinates: [Coordinate] = []

    func searchAddress(query: String) async throws -> [Address] {
        callCount += 1
        queries.append(query)
        return try result.get()
    }

    func reverseGeocode(latitude: Double, longitude: Double) async throws -> Address {
        reverseGeocodeCallCount += 1
        reverseGeocodeCoordinates.append(Coordinate(latitude: latitude, longitude: longitude))
        return try reverseGeocodeResult.get()
    }
}

final class SpotSearchMockLocationService: LocationServiceProtocol, @unchecked Sendable {
    var result: Result<Coordinate, any Error> = .success(Coordinate(latitude: 37.5209, longitude: 126.9833))
    var status: CLAuthorizationStatus = .authorizedWhenInUse
    var lastKnownLocation: Coordinate? {
        try? result.get()
    }

    func requestAuthorization() {}

    func authorizationStatus() -> CLAuthorizationStatus {
        status
    }

    func currentLocation() async throws -> Coordinate {
        try result.get()
    }

    func startUpdatingLocation() -> AsyncStream<Coordinate> {
        AsyncStream { continuation in
            if case let .success(coordinate) = result {
                continuation.yield(coordinate)
            }
            continuation.finish()
        }
    }
}

extension Address {
    static func fixture(
        id: String = "address-1",
        name: String? = "잠원 한강공원",
        fullAddress: String = "서울 서초구 잠원로 221-124 잠원한강공원",
        coordinate: Coordinate? = Coordinate(latitude: 37.5209, longitude: 127.0116)
    ) -> Address {
        Address(
            id: id,
            name: name,
            fullAddress: fullAddress,
            roadAddress: fullAddress,
            jibunAddress: nil,
            zipCode: nil,
            city: "서울",
            district: "서초구",
            coordinate: coordinate
        )
    }
}
