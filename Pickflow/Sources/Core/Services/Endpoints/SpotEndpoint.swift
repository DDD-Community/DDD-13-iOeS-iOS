import Alamofire
import Foundation

enum SpotEndpoint: APIEndpoint {
    case list(page: Int?, theme: String?, latitude: Double?, longitude: Double?)
    case detail(spotId: Int64)
    case viewport(Viewport)

    var baseURL: String { APIBaseURL.current }

    var path: String {
        switch self {
        case .list: "/v1/spots"
        case let .detail(spotId): "/v1/spots/\(spotId)"
        case .viewport: "/v1/spots/viewport"
        }
    }

    var method: HTTPMethod { .get }

    var parameters: Parameters? {
        switch self {
        case let .list(page, theme, latitude, longitude):
            var p: Parameters = [:]
            if let page { p["page"] = page }
            if let theme { p["theme"] = theme }
            if let latitude { p["latitude"] = latitude }
            if let longitude { p["longitude"] = longitude }
            return p.isEmpty ? nil : p
        case .detail:
            nil
        case let .viewport(viewport):
            [
                "topLeftLat": viewport.topLeft.latitude,
                "topLeftLng": viewport.topLeft.longitude,
                "topRightLat": viewport.topRight.latitude,
                "topRightLng": viewport.topRight.longitude,
                "bottomLeftLat": viewport.bottomLeft.latitude,
                "bottomLeftLng": viewport.bottomLeft.longitude,
                "bottomRightLat": viewport.bottomRight.latitude,
                "bottomRightLng": viewport.bottomRight.longitude,
            ]
        }
    }
}
