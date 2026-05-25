import CoreLocation
import Foundation

protocol LocationServiceProtocol: Sendable {
    var lastKnownLocation: Coordinate? { get }
    func requestAuthorization()
    func authorizationStatus() -> CLAuthorizationStatus
    func currentLocation() async throws -> Coordinate
    func startUpdatingLocation() -> AsyncStream<Coordinate>
}

@MainActor
func getLocationService() -> LocationServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(LocationServiceProtocol.self) else {
        fatalError("LocationServiceProtocol is not registered in DIContainer")
    }
    return service
}
