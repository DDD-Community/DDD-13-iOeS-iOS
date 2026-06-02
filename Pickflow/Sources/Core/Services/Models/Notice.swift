import Foundation

/// 공지사항(게시판 masterId=1) 목록 항목.
struct NoticeListItem: Decodable, Sendable, Identifiable, Equatable {
    let postId: Int64
    let title: String
    /// 본문 미리보기용 텍스트. 목록 API가 내려줄 때만 채워지며, 없으면 미리보기 줄을 그리지 않는다.
    let content: String?
    let createdAt: String        // "2026-05-09"
    let pinned: Bool

    var id: Int64 { postId }

    init(postId: Int64, title: String, createdAt: String, pinned: Bool, content: String? = nil) {
        self.postId = postId
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.pinned = pinned
    }
}

/// 공지사항 목록 페이지.
struct NoticePage: Decodable, Sendable, Equatable {
    let items: [NoticeListItem]
    let page: Int
    let hasNext: Bool
}

/// 공지사항 상세.
struct NoticeDetail: Decodable, Sendable, Identifiable, Equatable {
    let masterId: Int64
    let postId: Int64
    let title: String
    let createdAt: String
    let content: String

    var id: Int64 { postId }
}
