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

    /// 저장된 스팟은 SpotListItem 으로 납작하게 만들지 않는다.
    /// 비공개 전환(isPrivate)·삭제(deleted) 여부가 그 과정에서 사라지기 때문이다.
    func fetchSavedSpots(page: Int, latitude: Double?, longitude: Double?) async throws -> SavedSpotPage {
        let envelope: APIEnvelope<SavedSpotPage> = try await networkManager.request(
            endpoint: ArchiveEndpoint.fetchSavedSpots(page: page, latitude: latitude, longitude: longitude)
        )
        return envelope.data
    }

    func fetchMySpots(page: Int, latitude: Double?, longitude: Double?) async throws -> MySpotListPage {
        let envelope: APIEnvelope<MySpotListPage> = try await networkManager.request(
            endpoint: ArchiveEndpoint.fetchMySpots(page: page, latitude: latitude, longitude: longitude)
        )
        return envelope.data
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
            let isPNG = data.prefix(4) == Data([0x89, 0x50, 0x4E, 0x47])
            let fileName = isPNG ? "archive.png" : "archive.jpg"
            let mimeType = isPNG ? "image/png" : "image/jpeg"
            form.append(data, withName: "archiveImage", fileName: fileName, mimeType: mimeType)
        }
        return envelope.data
    }
}
