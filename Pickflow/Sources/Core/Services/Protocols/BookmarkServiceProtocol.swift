import Foundation

protocol BookmarkServiceProtocol: Sendable {
    func addBookmark(spotId: Int64) async throws
    func deleteBookmark(spotId: Int64) async throws
}

@MainActor
func getBookmarkService() -> BookmarkServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(BookmarkServiceProtocol.self) else {
        fatalError("BookmarkServiceProtocol is not registered in DIContainer")
    }
    return service
}
