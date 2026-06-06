import Foundation

// MARK: - Token & Auth State

struct AuthToken: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
}

enum AuthState: Sendable {
    case signedOut
    case signedIn(AuthToken)
}

// MARK: - API Response Wrapper

struct ApiResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let data: T
}

// MARK: - Token Response (Kakao & Apple 공통)

struct TokenResponse: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let profile: UserProfile
}

struct UserProfile: Decodable, Sendable {
    let userId: String
    let email: String?
    let nickname: String
    let profileImageUrl: String?
    let provider: SocialProvider
}

// MARK: - Apple Request User Info

struct AppleUserInfo: Sendable {
    let firstName: String?
    let lastName: String?
    let email: String?
}

// MARK: - Social Provider

enum SocialProvider: String, Codable, Sendable {
    case kakao = "KAKAO"
    case apple = "APPLE"
}

// MARK: - Withdrawal Restore (U007)

struct LoginFailureResponse: Decodable, Sendable {
    let code: String
    let message: String?
    let data: WithdrawalRestoreData?
}

struct WithdrawalRestoreData: Decodable, Sendable {
    let restoreToken: String
}

enum ProviderCredential: Sendable {
    case kakao(accessToken: String)
    case apple(identityToken: String, user: AppleUserInfo?)

    var isSocialKakao: Bool {
        if case .kakao = self { return true }
        return false
    }
}

// MARK: - AuthError

enum AuthError: LocalizedError {
    case unauthorized
    case forbidden
    case validation
    case external
    case withdrawalRestoreRequired(restoreToken: String, message: String?, credential: ProviderCredential)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized: "다시 로그인해 주세요."
        case .forbidden: "권한이 없습니다."
        case .validation: "입력값을 확인해 주세요."
        case .external: "일시적인 오류가 발생했어요. 잠시 후 다시 시도해 주세요."
        case .withdrawalRestoreRequired: "탈퇴 이력이 있습니다 재가입하시겠습니까?"
        case let .unknown(error): error.localizedDescription
        }
    }
}
