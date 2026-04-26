import Foundation

protocol SpotServiceProtocol: Sendable {
    func fetchSpotDetail(id: Int64, latitude: Double?, longitude: Double?) async throws -> SpotDetail
}

@MainActor
func getSpotService() -> SpotServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(SpotServiceProtocol.self) else {
        fatalError("SpotServiceProtocol is not registered in DIContainer")
    }
    return service
}
