import Foundation

final class ClusteringService: ClusteringServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func fetchClusterableSpots(viewport: Viewport, theme: String?) async throws -> [ClusterableSpot] {
        // TODO(BE-API): 서버 동작 확정 후 실제 호출로 교체.
        // try await networkManager.request(endpoint: ClusteringEndpoint(viewport: viewport, theme: theme))
        try await Task.sleep(for: .milliseconds(150))
        return ClusteringService.stubFixture(viewport: viewport)
    }

    func fetchMySpots(viewport: Viewport) async throws -> [MySpot] {
        // TODO(BE-API): 서버 동작 확정 후 실제 호출로 교체.
        // try await networkManager.request(endpoint: MySpotsEndpoint(viewport: viewport))
        try await Task.sleep(for: .milliseconds(150))
        return ClusteringService.stubMySpotsFixture()
    }

    /// 디버그 진입점에서 클러스터가 사진(왕십리/영동대교/한남) 같이 보이도록 큐레이션 스팟 60개 fixture.
    /// 서버 동작 후 viewport 기반 실제 응답으로 교체.
    private static func stubFixture(viewport _: Viewport) -> [ClusterableSpot] {
        var spots: [ClusterableSpot] = []
        var nextId: Int64 = 1

        // 왕십리역 부근 30개 (lat 37.560~37.563, lng 127.035~127.040)
        for _ in 0..<30 {
            spots.append(ClusterableSpot(
                id: nextId,
                coordinate: Coordinate(
                    latitude: 37.560 + Double.random(in: -0.0015...0.0015),
                    longitude: 127.035 + Double.random(in: -0.0025...0.0025)
                )
            ))
            nextId += 1
        }

        // 영동대교 부근 15개 (lat 37.530, lng 127.060)
        for _ in 0..<15 {
            spots.append(ClusterableSpot(
                id: nextId,
                coordinate: Coordinate(
                    latitude: 37.530 + Double.random(in: -0.0015...0.0015),
                    longitude: 127.060 + Double.random(in: -0.002...0.002)
                )
            ))
            nextId += 1
        }

        // 한남IC 남쪽(잠원) 부근 15개 (lat 37.515, lng 127.015)
        for _ in 0..<15 {
            spots.append(ClusterableSpot(
                id: nextId,
                coordinate: Coordinate(
                    latitude: 37.515 + Double.random(in: -0.0015...0.0015),
                    longitude: 127.015 + Double.random(in: -0.002...0.002)
                )
            ))
            nextId += 1
        }

        return spots
    }

    /// 디버그용 my spot fixture — 왕십리역 동측 1개 + 잠원 동측 1개 (큐레이션 클러스터 사이에 배치).
    private static func stubMySpotsFixture() -> [MySpot] {
        [
            MySpot(id: 1001, coordinate: Coordinate(latitude: 37.555, longitude: 127.054)),
            MySpot(id: 1002, coordinate: Coordinate(latitude: 37.516, longitude: 127.030)),
        ]
    }
}
