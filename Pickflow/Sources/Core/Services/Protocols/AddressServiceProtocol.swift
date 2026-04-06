import Foundation

protocol AddressServiceProtocol: Sendable {
    func searchAddress(query: String) async throws -> [Address]
    func reverseGeocode(latitude: Double, longitude: Double) async throws -> Address
}

struct Address: Codable, Sendable, Identifiable {
    let id: String
    let fullAddress: String
    let roadAddress: String?
    let jibunAddress: String?
    let zipCode: String?
    let city: String?
    let district: String?
    let coordinate: Coordinate?
}

@MainActor
func getAddressService() -> AddressServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(AddressServiceProtocol.self) else {
        fatalError("AddressServiceProtocol is not registered in DIContainer")
    }
    return service
}
