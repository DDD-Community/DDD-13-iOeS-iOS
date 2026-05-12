import Alamofire
import Foundation

struct AddressEndpoint: APIEndpoint {
    let query: String

    var baseURL: String { APIBaseURL.current }
    var path: String { "/api/address/search" }
    var method: HTTPMethod { .get }
    var parameters: Parameters? { ["query": query] }
}
