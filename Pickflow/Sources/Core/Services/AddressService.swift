import Foundation

final class AddressService: AddressServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func searchAddress(query: String) async throws -> [Address] {
        try await networkManager.request(endpoint: AddressEndpoint(query: query))
    }

    func reverseGeocode(latitude: Double, longitude: Double) async throws -> Address {
        // TODO: Implement with actual endpoint
        fatalError("Not implemented")
    }
}
