import Alamofire
import Foundation

struct SpotListEndpoint: APIEndpoint {
    let page: Int
    let theme: SpotTheme?
    let sort: SpotListSort?
    let latitude: Double?
    let longitude: Double?

    var baseURL: String { APIBaseURL.current }
    var path: String { "/v1/spots" }
    var method: HTTPMethod { .get }
    var parameters: Parameters? {
        var parameters: Parameters = ["page": page]
        if let theme {
            parameters["theme"] = theme.apiCode
        }
        if let sort {
            parameters["sort"] = sort.apiCode
        }
        if let latitude {
            parameters["latitude"] = latitude
        }
        if let longitude {
            parameters["longitude"] = longitude
        }
        return parameters
    }
}
