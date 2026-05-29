import Combine
import CoreLocation
import Foundation

@MainActor
final class SpotSearchViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded([Address])
        case empty
        case failed(String)
    }

    @Published private(set) var state: LoadState = .idle
    @Published var searchQuery: String = ""

    var onSelectAddress: ((Address) -> Void)?

    private let addressService: AddressServiceProtocol
    private let locationService: LocationServiceProtocol
    private var currentCoordinate: Coordinate?

    init(addressService: AddressServiceProtocol, locationService: LocationServiceProtocol) {
        self.addressService = addressService
        self.locationService = locationService
    }

    func search() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            state = .idle
            return
        }

        state = .loading

        async let location = try? locationService.currentLocation()

        do {
            let addresses = try await addressService.searchAddress(query: query)
            currentCoordinate = await location
            state = addresses.isEmpty ? .empty : .loaded(addresses)
        } catch {
            currentCoordinate = await location
            state = .failed(error.localizedDescription)
        }
    }

    func selectAddress(_ address: Address) {
        onSelectAddress?(address)
    }

    func distanceText(for address: Address) -> String? {
        let status = locationService.authorizationStatus()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            return nil
        }
        guard let currentCoordinate,
              let destination = address.coordinate else {
            return nil
        }

        let originLocation = CLLocation(
            latitude: currentCoordinate.latitude,
            longitude: currentCoordinate.longitude
        )
        let destinationLocation = CLLocation(
            latitude: destination.latitude,
            longitude: destination.longitude
        )
        let distanceInKilometers = originLocation.distance(from: destinationLocation) / 1_000

        return String(format: "%.1fkm", distanceInKilometers)
    }
}
