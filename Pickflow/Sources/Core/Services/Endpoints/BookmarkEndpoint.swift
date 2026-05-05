import Alamofire
import Foundation

enum BookmarkEndpoint: APIEndpoint {
    case add(spotId: Int64)
    case delete(spotId: Int64)

    var baseURL: String { APIBaseURL.current }

    var path: String {
        switch self {
        case .add:
            "/bookmarks"
        case let .delete(spotId):
            "/bookmarks/\(spotId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .add:
            .post
        case .delete:
            .delete
        }
    }

    var parameters: Parameters? {
        switch self {
        case let .add(spotId):
            ["spot_id": spotId]
        case .delete:
            nil
        }
    }
}
