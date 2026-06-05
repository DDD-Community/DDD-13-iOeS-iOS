import Foundation

protocol ArchiveServiceProtocol: Sendable {
    func fetchArchiveInfo() async throws -> ArchiveInfo
    func fetchSavedSpots(page: Int, latitude: Double?, longitude: Double?) async throws -> SpotListPage
    func fetchMySpots(page: Int, latitude: Double?, longitude: Double?) async throws -> MySpotListPage
    func renameArchive(_ name: String) async throws -> ArchiveInfo
    func uploadArchiveImage(_ data: Data) async throws -> ArchiveInfo
}

@MainActor
func getArchiveService() -> ArchiveServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(ArchiveServiceProtocol.self) else {
        fatalError("ArchiveServiceProtocol is not registered in DIContainer")
    }
    return service
}
