import Alamofire
import Foundation

struct SpotEndpoint: APIEndpoint {
    let id: Int64
    let latitude: Double?
    let longitude: Double?

    var baseURL: String { APIBaseURL.current }
    var path: String { "/spots/\(id)" }
    var method: HTTPMethod { .get }
    var parameters: Parameters? {
        var parameters: Parameters = [:]
        if let latitude {
            parameters["latitude"] = latitude
        }
        if let longitude {
            parameters["longitude"] = longitude
        }
        return parameters.isEmpty ? nil : parameters
    }
}
