import Foundation

protocol ClusteringServiceProtocol: Sendable {
    /// viewport 1회 호출로 큐레이션 스팟과 my spot을 동시에 가져온다.
    /// 두 종류 모두 동일 `/spots/viewport` 응답의 `isMySpot` 플래그로 분기되므로 한 번의 네트워크 호출로 충분하다.
    /// - TODO(BE-API): 응답 스키마 확정 시 ClusterableSpot / MySpot 메타 필드(theme/thumbnail 등) 보강.
    func fetchSpots(viewport: Viewport, themes: Set<SpotTheme>) async throws -> (curation: [ClusterableSpot], mySpots: [MySpot])
}

@MainActor
func getClusteringService() -> ClusteringServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(ClusteringServiceProtocol.self) else {
        fatalError("ClusteringServiceProtocol is not registered in DIContainer")
    }
    return service
}
