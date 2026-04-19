import Alamofire
import Foundation

/// 인증 관련 엔드포인트.
///
/// - Base URL: `AppConfig.baseURL`
/// - 공통 헤더: `Content-Type: application/json`
/// - 🔒 필요 엔드포인트(`logout`)의 Bearer 헤더 주입은 KAN-48(KeyChain) 완료 후 활성화한다.
enum AuthEndpoint: APIEndpoint {
    case kakaoSignIn(token: String)
    case refresh(refreshToken: String)
    case logout

    var baseURL: String { AppConfig.baseURL }

    var path: String {
        switch self {
        case .kakaoSignIn: "/auth/kakao"
        case .refresh: "/auth/refresh"
        case .logout: "/auth/logout"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .kakaoSignIn, .refresh, .logout: .post
        }
    }

    var parameters: Parameters? {
        switch self {
        case let .kakaoSignIn(token):
            ["kakao_access_token": token]
        case let .refresh(refreshToken):
            ["refresh_token": refreshToken]
        case .logout:
            nil
        }
    }

    var headers: HTTPHeaders? {
        switch self {
        case .logout:
            // TODO(KAN-48): TokenStore에서 access_token 가져와 Bearer 헤더 부착.
            nil
        default:
            nil
        }
    }
}
