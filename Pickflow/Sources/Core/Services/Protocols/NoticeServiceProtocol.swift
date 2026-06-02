import Foundation

protocol NoticeServiceProtocol: Sendable {
    func fetchNotices(masterId: Int64, page: Int) async throws -> NoticePage
    func fetchNoticeDetail(postId: Int64, masterId: Int64) async throws -> NoticeDetail
}

@MainActor
func getNoticeService() -> NoticeServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(NoticeServiceProtocol.self) else {
        fatalError("NoticeServiceProtocol is not registered in DIContainer")
    }
    return service
}
