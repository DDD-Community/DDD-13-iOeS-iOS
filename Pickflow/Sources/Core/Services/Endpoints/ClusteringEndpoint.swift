import Alamofire
import Foundation

struct ClusteringEndpoint: APIEndpoint {
    let viewport: Viewport
    let theme: String?

    var baseURL: String { APIBaseURL.current }
    var path: String { "/clustering" }
    var method: HTTPMethod { .get }
    var parameters: Parameters? {
        var parameters: Parameters = [
            "topLeftLatitude": viewport.topLeft.latitude,
            "topLeftLongitude": viewport.topLeft.longitude,
            "topRightLatitude": viewport.topRight.latitude,
            "topRightLongitude": viewport.topRight.longitude,
            "bottomLeftLatitude": viewport.bottomLeft.latitude,
            "bottomLeftLongitude": viewport.bottomLeft.longitude,
            "bottomRightLatitude": viewport.bottomRight.latitude,
            "bottomRightLongitude": viewport.bottomRight.longitude,
        ]
        if let theme {
            parameters["theme"] = theme
        }
        return parameters
    }
}
