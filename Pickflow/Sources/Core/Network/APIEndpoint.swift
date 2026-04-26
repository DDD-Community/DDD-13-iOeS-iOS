import Alamofire
import Foundation

protocol APIEndpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: HTTPHeaders? { get }
    var parameters: Parameters? { get }
    var encoding: any ParameterEncoding { get }
}

extension APIEndpoint {
    var url: String { baseURL + path }
    var headers: HTTPHeaders? { nil }
    var parameters: Parameters? { nil }
    var encoding: any ParameterEncoding {
        switch method {
        case .get:
            URLEncoding.default
        default:
            JSONEncoding.default
        }
    }
}
