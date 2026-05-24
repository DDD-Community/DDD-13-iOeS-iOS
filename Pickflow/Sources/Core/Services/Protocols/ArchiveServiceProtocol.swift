import Foundation

protocol ArchiveServiceProtocol: Sendable {
    // FIXME(BE-API): 응답이 SpotListPage와 다른 구조면 ArchivePage 별도 정의
    func fetchArchive(page: Int) async throws -> SpotListPage
}

@MainActor
func getArchiveService() -> ArchiveServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(ArchiveServiceProtocol.self) else {
        fatalError("ArchiveServiceProtocol is not registered in DIContainer")
    }
    return service
}
