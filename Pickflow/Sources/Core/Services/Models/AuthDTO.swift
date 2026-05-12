import Foundation

// MARK: - Token & Auth State

/// 백엔드에서 발급되는 인증 토큰 쌍.
struct AuthToken: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
}

/// 앱 진입 시 판정되는 인증 상태.
enum AuthState: Sendable {
    case signedOut
    case signedIn(AuthToken)
}

// MARK: - Responses

/// `POST /auth/kakao` 응답. snake_case → camelCase 는
/// `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase` 로 매핑.
struct KakaoSignInResponse: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let isNewUser: Bool
    let user: AuthUser
}

/// `POST /auth/apple` 응답. 카카오 로그인 응답과 동일한 shape를 사용한다.
struct AppleSignInResponse: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let isNewUser: Bool
    let user: AuthUser
}

/// 로그인 응답에 포함되는 사용자 정보.
struct AuthUser: Decodable, Sendable {
    let id: Int64
    let nickname: String
    let socialProvider: SocialProvider
}

/// 소셜 로그인 제공자.
enum SocialProvider: String, Decodable, Sendable {
    case kakao
    case apple
}

// MARK: - AuthError

/// 백엔드 공통 에러 코드 → 앱 도메인 에러 매핑.
/// `LoginViewModel.errorMessage`는 `errorDescription`을 사용자에게 노출한다.
enum AuthError: LocalizedError {
    case unauthorized
    case forbidden
    case validation
    case external
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized: "다시 로그인해 주세요."
        case .forbidden: "권한이 없습니다."
        case .validation: "입력값을 확인해 주세요."
        case .external: "일시적인 오류가 발생했어요. 잠시 후 다시 시도해 주세요."
        case let .unknown(error): error.localizedDescription
        }
    }
}
