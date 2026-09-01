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
    // TODO(BE-API, PV-64): 파라미터명 확정되면 갱신. 큐레이션 스팟만 필터링되고 내 MY스팟은 지역 무관 항상 포함되어야 한다(BE 확인 완료).
    let regionId: Int?

    var baseURL: String { APIBaseURL.current }
    var path: String { "/v1/spots/viewport" }
    var method: HTTPMethod { .get }
    // 카테고리 다중선택이 반복 파라미터라 대괄호 없는 배열 인코딩이 필요하다.
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
        ]
        if let themeValues = SpotThemeQuery.values(for: themes) {
            p[SpotThemeQuery.parameterName] = themeValues
        }
        if let regionId {
            p["regionId"] = regionId
        }
        return p
    }
}
