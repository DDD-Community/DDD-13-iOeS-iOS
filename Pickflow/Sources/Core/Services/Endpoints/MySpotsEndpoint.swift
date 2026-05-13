import Alamofire
import Foundation

struct MySpotsEndpoint: APIEndpoint {
    let viewport: Viewport

    var baseURL: String { APIBaseURL.current }
    var path: String { "/my-spots" }
    var method: HTTPMethod { .get }
    var parameters: Parameters? {
        [
            "topLeftLatitude": viewport.topLeft.latitude,
            "topLeftLongitude": viewport.topLeft.longitude,
            "topRightLatitude": viewport.topRight.latitude,
            "topRightLongitude": viewport.topRight.longitude,
            "bottomLeftLatitude": viewport.bottomLeft.latitude,
            "bottomLeftLongitude": viewport.bottomLeft.longitude,
            "bottomRightLatitude": viewport.bottomRight.latitude,
            "bottomRightLongitude": viewport.bottomRight.longitude,
        ]
    }
}
