import Foundation

protocol ClusteringServiceProtocol: Sendable {
    /// viewport 영역 안의 큐레이션 스팟을 NMCClusterer 입력 양식으로 가져온다.
    /// - TODO(BE-API): 응답 스키마 확정 시 ClusterableSpot 메타 필드(theme/thumbnail 등) 보강.
    func fetchClusterableSpots(viewport: Viewport, theme: String?) async throws -> [ClusterableSpot]

    /// viewport 영역 안의 my spot(사용자 등록)을 가져온다. 클러스터링에 참여하지 않고 단일 마커로 표시.
    /// - TODO(BE-API): 응답 스키마 확정 시 MySpot 메타 필드(thumbnail 등) 보강.
    func fetchMySpots(viewport: Viewport) async throws -> [MySpot]
}

@MainActor
func getClusteringService() -> ClusteringServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(ClusteringServiceProtocol.self) else {
        fatalError("ClusteringServiceProtocol is not registered in DIContainer")
    }
    return service
}
