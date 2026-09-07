import Alamofire
import Foundation

enum RegionEndpoint: APIEndpoint {
    case activeList

    var baseURL: String { APIBaseURL.current }

    var path: String {
        switch self {
        case .activeList: "/v1/regions"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .activeList: .get
        }
    }
}
