import Foundation

protocol RegionServiceProtocol: Sendable {
    /// 활성 지역 목록을 조회한다. 노출 순서가 곧 기본값 우선순위(대전 우선)다.
    func fetchActiveRegions() async throws -> [Region]
}

@MainActor
func getRegionService() -> RegionServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(RegionServiceProtocol.self) else {
        fatalError("RegionServiceProtocol is not registered in DIContainer")
    }
    return service
}
