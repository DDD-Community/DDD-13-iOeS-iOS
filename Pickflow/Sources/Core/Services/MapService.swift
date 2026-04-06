import Foundation

final class MapService: MapServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func searchPlaces(query: String, coordinate: Coordinate) async throws -> [Place] {
        // TODO: Implement with actual endpoint
        fatalError("Not implemented")
    }

    func fetchPlaceDetail(id: String) async throws -> PlaceDetail {
        // TODO: Implement with actual endpoint
        fatalError("Not implemented")
    }

    func calculateRoute(from: Coordinate, to: Coordinate) async throws -> Route {
        // TODO: Implement with actual endpoint
        fatalError("Not implemented")
    }
}
