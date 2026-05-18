import Alamofire
import Foundation

enum BookmarkEndpoint: APIEndpoint {
    case add(spotId: Int64)
    case delete(spotId: Int64)

    var baseURL: String { APIBaseURL.current }

    var path: String {
        switch self {
        case let .add(spotId), let .delete(spotId):
            "/v1/spots/\(spotId)/bookmarks"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .add: .post
        case .delete: .delete
        }
    }

    var parameters: Parameters? { nil }
}
