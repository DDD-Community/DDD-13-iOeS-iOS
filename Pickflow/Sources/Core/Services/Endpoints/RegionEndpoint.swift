import Alamofire
import Foundation

// TODO(BE-API, PV-64): 활성지역 조회 API 경로/파라미터 확정되면 갱신.
enum RegionEndpoint: APIEndpoint {
    case activeList

    var baseURL: String { APIBaseURL.current }

    var path: String {
        switch self {
        case .activeList: "/v1/regions/active"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .activeList: .get
        }
    }
}
