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
    // 카테고리 다중선택이 반복 파라미터라 대괄호 없는 배열 인코딩이 필요하다.
    var encoding: any ParameterEncoding { SpotThemeQuery.encoding }
    var parameters: Parameters? {
        // 서버 제약: 위/경도 소수점 6자리까지 허용. (KAN-107)
        let r: (Double) -> Double = { (($0 * 1_000_000).rounded()) / 1_000_000 }
        var parameters: Parameters = ["page": page]
        if let themeValues = SpotThemeQuery.values(for: themes) {
            parameters[SpotThemeQuery.parameterName] = themeValues
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
