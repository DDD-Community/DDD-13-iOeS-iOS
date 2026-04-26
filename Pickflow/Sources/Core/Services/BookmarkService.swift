import Foundation

final class BookmarkService: BookmarkServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func addBookmark(spotId: Int64) async throws {
        do {
            let _: EmptyResponse = try await networkManager.request(endpoint: BookmarkEndpoint.add(spotId: spotId))
        } catch BookmarkError.alreadyBookmarked {
            return
        } catch {
            throw error
        }
    }

    func deleteBookmark(spotId: Int64) async throws {
        let _: EmptyResponse = try await networkManager.request(endpoint: BookmarkEndpoint.delete(spotId: spotId))
    }
}
