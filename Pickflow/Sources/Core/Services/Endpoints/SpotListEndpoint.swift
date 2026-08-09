import Alamofire
import Foundation

struct SpotListEndpoint: APIEndpoint {
    let page: Int
    let themes: Set<SpotTheme>
    let sort: SpotListSort?
    let latitude: Double?
    let longitude: Double?

    var baseURL: String { APIBaseURL.current }
    var path: String { "/v1/spots" }
    var method: HTTPMethod { .get }
    var parameters: Parameters? {
        // 서버 제약: 위/경도 소수점 6자리까지 허용. (KAN-107)
        let r: (Double) -> Double = { (($0 * 1_000_000).rounded()) / 1_000_000 }
        var parameters: Parameters = ["page": page]
        if let themeValue = SpotThemeQuery.value(for: themes) {
            parameters[SpotThemeQuery.parameterName] = themeValue
        }
        if let sort {
            parameters["sort"] = sort.apiCode
        }
        if let latitude {
            parameters["latitude"] = r(latitude)
        }
        if let longitude {
            parameters["longitude"] = r(longitude)
        }
        return parameters
    }
}
