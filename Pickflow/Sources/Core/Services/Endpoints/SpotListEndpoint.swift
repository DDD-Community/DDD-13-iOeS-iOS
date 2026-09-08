import Alamofire
import Foundation

struct SpotListEndpoint: APIEndpoint {
    let page: Int
    let themes: Set<SpotTheme>
    let sort: SpotListSort?
    let latitude: Double?
    let longitude: Double?
    /// 서버 스펙상 필수 파라미터. 다중 선택 대비 배열이지만(`regionId=1&regionId=2`),
    /// 현재 UI는 단일 선택만 지원하므로 항상 원소 1개로 보낸다.
    let regionId: Int

    var baseURL: String { APIBaseURL.current }
    var path: String { "/v1/spots" }
    var method: HTTPMethod { .get }
    // 카테고리/지역 다중선택이 반복 파라미터라 대괄호 없는 배열 인코딩이 필요하다.
    var encoding: any ParameterEncoding { SpotThemeQuery.encoding }
    var parameters: Parameters? {
        // 서버 제약: 위/경도 소수점 6자리까지 허용. (KAN-107)
        let r: (Double) -> Double = { (($0 * 1_000_000).rounded()) / 1_000_000 }
        var parameters: Parameters = ["page": page, "regionId": [regionId]]
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
