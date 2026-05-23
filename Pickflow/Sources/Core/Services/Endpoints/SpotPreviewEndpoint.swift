import Alamofire
import Foundation

struct SpotPreviewEndpoint: APIEndpoint {
    let spotId: Int64
    let latitude: Double?
    let longitude: Double?

    var baseURL: String { APIBaseURL.current }
    var path: String { "/v1/spots/\(spotId)/preview" }
    var method: HTTPMethod { .get }
    var parameters: Parameters? {
        var p: Parameters = [:]
        if let latitude { p["latitude"] = latitude }
        if let longitude { p["longitude"] = longitude }
        return p.isEmpty ? nil : p
    }
}
