import Foundation

final class NoticeService: NoticeServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func fetchNotices(masterId: Int64, page: Int) async throws -> NoticePage {
        let envelope: APIEnvelope<NoticePage> = try await networkManager.request(
            endpoint: NoticeEndpoint.list(masterId: masterId, page: page)
        )
        return envelope.data
    }

    func fetchNoticeDetail(postId: Int64, masterId: Int64) async throws -> NoticeDetail {
        let envelope: APIEnvelope<NoticeDetail> = try await networkManager.request(
            endpoint: NoticeEndpoint.detail(postId: postId, masterId: masterId)
        )
        return envelope.data
    }
}
