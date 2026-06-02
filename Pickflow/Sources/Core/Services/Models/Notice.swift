import Foundation

/// 공지사항(게시판 masterId=1) 목록 항목.
struct NoticeListItem: Decodable, Sendable, Identifiable, Equatable {
    let postId: Int64
    let title: String
    let createdAt: String        // "2026-05-09"
    let pinned: Bool

    var id: Int64 { postId }
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
