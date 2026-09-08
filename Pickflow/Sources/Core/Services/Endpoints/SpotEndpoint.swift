import Alamofire
import Foundation

enum SpotEndpoint: APIEndpoint {
    case list(page: Int?, theme: String?, latitude: Double?, longitude: Double?)
    case detail(spotId: Int64)
    case register

    var baseURL: String { APIBaseURL.current }

    var path: String {
        switch self {
        case .list: "/v1/spots"
        case let .detail(spotId): "/v1/spots/\(spotId)"
        case .register: "/v1/users/me/my-spots"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list, .detail: .get
        case .register: .post
        }
    }

    var parameters: Parameters? {
        switch self {
        case let .list(page, theme, latitude, longitude):
            var p: Parameters = [:]
            if let page { p["page"] = page }
            if let theme { p["theme"] = theme }
            if let latitude { p["latitude"] = latitude }
            if let longitude { p["longitude"] = longitude }
            return p.isEmpty ? nil : p
        case .detail, .register:
            return nil
        }
    }
}

struct SpotViewportEndpoint: APIEndpoint {
    let viewport: Viewport
    let themes: Set<SpotTheme>
    /// 서버 스펙상 필수 파라미터, bbox 범위와 AND 조건으로 결합된다.
    /// TODO(BE-API 확인 필요, PV-64): 내 MY스팟이 이 필터와 무관하게 항상 포함되는지 스펙 문서에
    /// 명시돼 있지 않음 — bbox 안이라도 선택 지역 밖 MY스팟이 잘려나가지 않는지 BE에 재확인 필요.
    let regionId: Int

    var baseURL: String { APIBaseURL.current }
    var path: String { "/v1/spots/viewport" }
    var method: HTTPMethod { .get }
    // 카테고리/지역 다중선택이 반복 파라미터라 대괄호 없는 배열 인코딩이 필요하다.
    var encoding: any ParameterEncoding { SpotThemeQuery.encoding }
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
            "regionId": [regionId],
        ]
        if let themeValues = SpotThemeQuery.values(for: themes) {
            p[SpotThemeQuery.parameterName] = themeValues
        }
        return p
    }
}
