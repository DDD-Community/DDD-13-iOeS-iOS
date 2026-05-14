import Alamofire
import Foundation

/// 인증 관련 엔드포인트.
///
/// - Base URL: `AppConfig.baseURL`
/// - 공통 헤더: `Content-Type: application/json`
/// - 🔒 필요 엔드포인트(`logout`)의 Bearer 헤더 주입은 KAN-48(KeyChain) 완료 후 활성화한다.
enum AuthEndpoint: APIEndpoint {
    case kakaoSignIn(token: String)
    case appleSignIn(identityToken: String, nonce: String)
    case refresh(refreshToken: String)
    case logout(refreshToken: String)

    var baseURL: String { AppConfig.baseURL }

    var path: String {
        switch self {
        case .kakaoSignIn: "/v1/auth/kakao"
        case .appleSignIn: "/v1/auth/apple"
        case .refresh: "/v1/auth/refresh"
        case .logout: "/v1/auth/logout"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .kakaoSignIn, .appleSignIn, .refresh, .logout: .post
        }
    }

    var parameters: Parameters? {
        switch self {
        case let .kakaoSignIn(token):
            ["kakao_access_token": token]
        case let .appleSignIn(identityToken, nonce):
            [
                "identity_token": identityToken,
                "nonce": nonce,
            ]
        case let .refresh(refreshToken):
            ["refreshToken": refreshToken]
        case let .logout(refreshToken):
            ["refreshToken": refreshToken]
        }
    }
}
