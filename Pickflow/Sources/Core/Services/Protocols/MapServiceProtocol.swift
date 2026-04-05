import Foundation

protocol MapServiceProtocol: Sendable {
    func searchPlaces(query: String, coordinate: Coordinate) async throws -> [Place]
    func fetchPlaceDetail(id: String) async throws -> PlaceDetail
    func calculateRoute(from: Coordinate, to: Coordinate) async throws -> Route
}

struct Place: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let address: String
    let coordinate: Coordinate
    let category: String?
}

struct PlaceDetail: Codable, Sendable {
    let id: String
    let name: String
    let address: String
    let coordinate: Coordinate
    let category: String?
    let phoneNumber: String?
    let openingHours: String?
}

struct Route: Codable, Sendable {
    let distanceMeters: Double
    let estimatedTimeSeconds: Double
    let polylinePoints: [Coordinate]
}

@MainActor
func getMapService() -> MapServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(MapServiceProtocol.self) else {
        fatalError("MapServiceProtocol is not registered in DIContainer")
    }
    return service
}
