import CoreLocation
import Foundation

final class LocationService: NSObject, LocationServiceProtocol, @unchecked Sendable {
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<Coordinate, any Error>?
    private(set) var lastKnownLocation: Coordinate?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func authorizationStatus() -> CLAuthorizationStatus {
        locationManager.authorizationStatus
    }

    func currentLocation() async throws -> Coordinate {
        if let cached = lastKnownLocation { return cached }
        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()
        }
    }

    func startUpdatingLocation() -> AsyncStream<Coordinate> {
        AsyncStream { continuation in
            let delegate = StreamingDelegate(continuation: continuation, onLocation: { [weak self] coord in
                self?.lastKnownLocation = coord
            })
            objc_setAssociatedObject(self, &StreamingDelegate.key, delegate, .OBJC_ASSOCIATION_RETAIN)
            locationManager.delegate = delegate
            locationManager.startUpdatingLocation()

            continuation.onTermination = { [weak self] _ in
                self?.locationManager.stopUpdatingLocation()
                self?.locationManager.delegate = self
            }
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = Coordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        lastKnownLocation = coordinate
        locationContinuation?.resume(returning: coordinate)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }
}

private final class StreamingDelegate: NSObject, CLLocationManagerDelegate {
    nonisolated(unsafe) static var key: UInt8 = 0
    private let continuation: AsyncStream<Coordinate>.Continuation
    private let onLocation: (Coordinate) -> Void

    init(continuation: AsyncStream<Coordinate>.Continuation, onLocation: @escaping (Coordinate) -> Void) {
        self.continuation = continuation
        self.onLocation = onLocation
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = Coordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        onLocation(coordinate)
        continuation.yield(coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {}
}
