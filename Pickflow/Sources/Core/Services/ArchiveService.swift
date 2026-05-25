import Foundation

final class ArchiveService: ArchiveServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func fetchArchiveInfo() async throws -> ArchiveInfo {
        let envelope: APIEnvelope<ArchiveInfo> = try await networkManager.request(
            endpoint: ArchiveEndpoint.fetchInfo
        )
        return envelope.data
    }

    func fetchSavedSpots(page: Int, latitude: Double?, longitude: Double?) async throws -> SpotListPage {
        let envelope: APIEnvelope<SavedSpotPage> = try await networkManager.request(
            endpoint: ArchiveEndpoint.fetchSavedSpots(page: page, latitude: latitude, longitude: longitude)
        )
        let spots = envelope.data.spots.map { $0.toSpotListItem() }
        return SpotListPage(spots: spots, page: envelope.data.page, hasNext: envelope.data.hasNext)
    }

    func renameArchive(_ name: String) async throws -> ArchiveInfo {
        let envelope: APIEnvelope<ArchiveInfo> = try await networkManager.requestJSON(
            endpoint: ArchiveEndpoint.renameArchive(name: name)
        )
        return envelope.data
    }

    func uploadArchiveImage(_ data: Data) async throws -> ArchiveInfo {
        let envelope: APIEnvelope<ArchiveInfo> = try await networkManager.upload(
            endpoint: ArchiveEndpoint.uploadImage
        ) { form in
            form.append(data, withName: "archiveImage", fileName: "archive.jpg", mimeType: "image/jpeg")
        }
        return envelope.data
    }
}
