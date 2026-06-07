import Alamofire
import Foundation

struct ReportEndpoint: APIEndpoint {
    let spotId: Int64
    let content: String

    var baseURL: String { APIBaseURL.current }
    var path: String { "/v1/spots/\(spotId)/reports" }
    var method: HTTPMethod { .post }
    var parameters: Parameters? { ["content": content] }
}
