import Foundation

/// 인증 도메인 서비스.
///
/// - Note: Kakao SDK 호출(= `kakaoAccessToken` 획득)은 본 프로토콜의 책임이 아니다.
///   외부에서 얻은 `kakaoAccessToken`을 인자로 받아 백엔드 로그인만 처리한다.
///   Kakao SDK 연동은 KAN-47 에서 `LoginViewModel.obtainKakaoAccessToken()` 스텁을 대체하며 이뤄진다.
protocol AuthServiceProtocol: Sendable {
    /// `POST /auth/kakao` 호출.
    func signInWithKakao(kakaoAccessToken: String) async throws -> KakaoSignInResponse

    /// `POST /auth/refresh` 호출.
    func refreshToken(_ refreshToken: String) async throws -> AuthToken

    /// `POST /auth/logout` 호출.
    func signOut() async throws

    /// 앱 진입 시 인증 상태 판정.
    ///
    /// - Note: 현재 구현은 항상 `.signedOut`을 반환하는 스텁이다.
    ///   KAN-48(KeyChain 토큰 저장) → KAN-49(자동 로그인)에서 실구현으로 대체된다.
    func currentAuthState() async -> AuthState
}

@MainActor
func getAuthService() -> AuthServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(AuthServiceProtocol.self) else {
        fatalError("AuthServiceProtocol is not registered in DIContainer")
    }
    return service
}
