import Alamofire
import Foundation

enum SpotEndpoint: APIEndpoint {
    case detail(spotId: Int64)

    var baseURL: String { APIBaseURL.current }

    var path: String {
        switch self {
        case let .detail(spotId): "/v1/spots/\(spotId)"
        }
    }

    var method: HTTPMethod { .get }

    var parameters: Parameters? { nil }
}

struct SpotViewportEndpoint: APIEndpoint {
    let viewport: Viewport
    let theme: SpotTheme?

    var baseURL: String { APIBaseURL.current }
    var path: String { "/v1/spots/viewport" }
    var method: HTTPMethod { .get }
    var parameters: Parameters? {
        // 서버 제약: 위/경도 소수점 6자리까지 허용. (KAN-107)
        let r: (Double) -> Double = { (($0 * 1_000_000).rounded()) / 1_000_000 }
        var p: Parameters = [
            "topLeftLat": r(viewport.topLeft.latitude),
            "topLeftLng": r(viewport.topLeft.longitude),
            "topRightLat": r(viewport.topRight.latitude),
            "topRightLng": r(viewport.topRight.longitude),
            "bottomLeftLat": r(viewport.bottomLeft.latitude),
            "bottomLeftLng": r(viewport.bottomLeft.longitude),
            "bottomRightLat": r(viewport.bottomRight.latitude),
            "bottomRightLng": r(viewport.bottomRight.longitude),
        ]
        if let theme {
            p["theme"] = theme.apiCode
        }
        return p
    }
}
