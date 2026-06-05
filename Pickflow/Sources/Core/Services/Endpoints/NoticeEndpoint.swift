import Alamofire
import Foundation

enum NoticeEndpoint: APIEndpoint {
    /// 게시글 목록 조회 (masterId=1: 공지사항, page 0부터)
    case list(masterId: Int64, page: Int)
    /// 게시글 상세 조회
    case detail(postId: Int64, masterId: Int64)

    var baseURL: String { APIBaseURL.current }

    var path: String {
        switch self {
        case .list:
            "/v1/bbs/posts"
        case let .detail(postId, _):
            "/v1/bbs/posts/\(postId)"
        }
    }

    var method: HTTPMethod { .get }

    var parameters: Parameters? {
        switch self {
        case let .list(masterId, page):
            ["masterId": masterId, "page": page]
        case let .detail(_, masterId):
            ["masterId": masterId]
        }
    }
}
