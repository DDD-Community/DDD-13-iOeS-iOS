import Foundation
@testable import Pickflow

final class MockNoticeService: NoticeServiceProtocol, @unchecked Sendable {
    var listResponder: @Sendable (Int64, Int) -> Result<NoticePage, any Error> = { _, _ in
        .success(NoticePage(items: [], page: 0, hasNext: false))
    }
    var detailResponder: @Sendable (Int64, Int64) -> Result<NoticeDetail, any Error> = { postId, masterId in
        .success(.fixture(masterId: masterId, postId: postId))
    }

    private(set) var requestedListPages: [Int] = []
    private(set) var requestedDetailIds: [Int64] = []
    private(set) var lastMasterId: Int64?

    func fetchNotices(masterId: Int64, page: Int) async throws -> NoticePage {
        lastMasterId = masterId
        requestedListPages.append(page)
        return try listResponder(masterId, page).get()
    }

    func fetchNoticeDetail(postId: Int64, masterId: Int64) async throws -> NoticeDetail {
        lastMasterId = masterId
        requestedDetailIds.append(postId)
        return try detailResponder(postId, masterId).get()
    }
}

extension NoticeListItem {
    static func fixture(
        postId: Int64 = 1,
        title: String = "공지 제목",
        createdAt: String = "2026-05-09",
        pinned: Bool = false,
        content: String? = nil
    ) -> NoticeListItem {
        NoticeListItem(postId: postId, title: title, createdAt: createdAt, pinned: pinned, content: content)
    }
}

extension NoticeDetail {
    static func fixture(
        masterId: Int64 = 1,
        postId: Int64 = 1,
        title: String = "공지 제목",
        createdAt: String = "2026-05-09",
        content: String = "본문 내용"
    ) -> NoticeDetail {
        NoticeDetail(masterId: masterId, postId: postId, title: title, createdAt: createdAt, content: content)
    }
}

enum NoticeTestError: Error { case stubbed }
