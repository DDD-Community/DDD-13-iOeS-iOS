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
        // 서버 제약: 위/경도 소수점 6자리까지 허용. (KAN-107)
        let r: (Double) -> Double = { (($0 * 1_000_000).rounded()) / 1_000_000 }
        var p: Parameters = [:]
        if let latitude { p["latitude"] = r(latitude) }
        if let longitude { p["longitude"] = r(longitude) }
        return p.isEmpty ? nil : p
    }
}
