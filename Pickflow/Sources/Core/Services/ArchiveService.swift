import Foundation

final class ArchiveService: ArchiveServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func fetchArchive(page: Int) async throws -> SpotListPage {
        let envelope: APIEnvelope<SpotListPage> = try await networkManager.request(
            endpoint: ArchiveEndpoint.fetchArchive(page: page)
        )
        return envelope.data
    }
}
