import CoreLocation
import Foundation

@MainActor
final class SpotLocationDetailViewModel: ObservableObject {
    @Published var currentCoordinate: Coordinate
    @Published var userLocation: Coordinate?
    @Published var cameraMoveRequest: CameraMoveRequest?
    @Published var isConfirming: Bool = false
    @Published var showLocationPermissionAlert: Bool = false

    private let originalAddress: Address
    private let addressService: AddressServiceProtocol
    private let locationService: LocationServiceProtocol

    var onConfirm: ((Address) -> Void)?

    init(
        originalAddress: Address,
        addressService: AddressServiceProtocol,
        locationService: LocationServiceProtocol
    ) {
        self.originalAddress = originalAddress
        self.addressService = addressService
        self.locationService = locationService
        self.currentCoordinate = originalAddress.coordinate ?? Coordinate(latitude: 0, longitude: 0)
    }

    func confirm(markerCoordinate: Coordinate) async {
        isConfirming = true
        defer { isConfirming = false }

        if let original = originalAddress.coordinate,
           original.isApproximatelyEqual(to: markerCoordinate) {
            onConfirm?(originalAddress)
            return
        }

        do {
            let newAddress = try await addressService.reverseGeocode(
                latitude: markerCoordinate.latitude,
                longitude: markerCoordinate.longitude
            )
            onConfirm?(newAddress)
        } catch {
            let fallback = Address(
                id: "reverse-fallback-\(markerCoordinate.latitude)-\(markerCoordinate.longitude)",
                name: originalAddress.name,
                fullAddress: originalAddress.fullAddress,
                roadAddress: originalAddress.roadAddress,
                jibunAddress: originalAddress.jibunAddress,
                zipCode: originalAddress.zipCode,
                city: originalAddress.city,
                district: originalAddress.district,
                coordinate: markerCoordinate
            )
            onConfirm?(fallback)
        }
    }

    func moveToCurrentLocation() async {
        switch locationService.authorizationStatus() {
        case .denied, .restricted:
            showLocationPermissionAlert = true
            return
        case .notDetermined:
            locationService.requestAuthorization()
        default:
            break
        }
        if let coordinate = try? await locationService.currentLocation() {
            userLocation = coordinate
            cameraMoveRequest = CameraMoveRequest(coordinate: coordinate, zoom: 16)
        }
    }

    func refreshUserLocation() async {
        guard locationService.authorizationStatus() != .notDetermined else { return }
        if let coordinate = try? await locationService.currentLocation() {
            userLocation = coordinate
        }
    }
}

private extension Coordinate {
    func isApproximatelyEqual(to other: Coordinate) -> Bool {
        abs(latitude - other.latitude) < 0.000001 && abs(longitude - other.longitude) < 0.000001
    }
}
