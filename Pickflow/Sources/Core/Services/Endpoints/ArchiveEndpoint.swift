import Alamofire
import Foundation

enum ArchiveEndpoint: APIEndpoint {
    case getImage
    case uploadImage

    var baseURL: String { APIBaseURL.current }
    var path: String { "/v1/users/me/archive" }

    var method: HTTPMethod {
        switch self {
        case .getImage: .get
        case .uploadImage: .post
        }
    }

    var parameters: Parameters? { nil }
}
