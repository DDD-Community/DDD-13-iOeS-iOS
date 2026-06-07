import Foundation
@testable import Pickflow

final class MockClusteringService: ClusteringServiceProtocol, @unchecked Sendable {
    var result: Result<[ClusterableSpot], any Error> = .success([])
    private(set) var requests: [(viewport: Viewport, theme: String?)] = []

    var mySpotsResult: Result<[MySpot], any Error> = .success([])
    private(set) var mySpotsRequests: [Viewport] = []

    func fetchSpots(viewport: Viewport, theme: String?) async throws -> (curation: [ClusterableSpot], mySpots: [MySpot]) {
        requests.append((viewport, theme))
        mySpotsRequests.append(viewport)
        let curation = try result.get()
        let mine = (try? mySpotsResult.get()) ?? []
        return (curation, mine)
    }
}

extension MySpot {
    static func fixture(
        id: Int64 = 100,
        latitude: Double = 37.55,
        longitude: Double = 127.05,
        imageUrl: String = ""
    ) -> MySpot {
        MySpot(id: id, coordinate: Coordinate(latitude: latitude, longitude: longitude), imageUrl: imageUrl)
    }
}

extension Viewport {
    static func fixture(
        topLeft: Coordinate = Coordinate(latitude: 37.6, longitude: 126.9),
        topRight: Coordinate = Coordinate(latitude: 37.6, longitude: 127.1),
        bottomLeft: Coordinate = Coordinate(latitude: 37.4, longitude: 126.9),
        bottomRight: Coordinate = Coordinate(latitude: 37.4, longitude: 127.1)
    ) -> Viewport {
        Viewport(topLeft: topLeft, topRight: topRight, bottomLeft: bottomLeft, bottomRight: bottomRight)
    }
}

extension ClusterableSpot {
    static func fixture(
        id: Int64 = 1,
        latitude: Double = 37.5,
        longitude: Double = 127.0,
        imageUrl: String = ""
    ) -> ClusterableSpot {
        ClusterableSpot(id: id, coordinate: Coordinate(latitude: latitude, longitude: longitude), imageUrl: imageUrl)
    }
}
