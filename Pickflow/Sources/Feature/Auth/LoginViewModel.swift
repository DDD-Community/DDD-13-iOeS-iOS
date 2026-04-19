import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var didSignInSucceed = false
    @Published private(set) var isNewUser = false

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    // MARK: - Intent

    func signInWithKakaoTapped() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            // 1) Kakao SDK로 kakaoAccessToken 획득.
            //    본 티켓(KAN-46)에서는 스텁이며, 실제 구현은 KAN-47에서 대체된다.
            let kakaoAccessToken = try await obtainKakaoAccessToken()

            // 2) 백엔드 POST /auth/kakao 호출.
            let response = try await authService.signInWithKakao(kakaoAccessToken: kakaoAccessToken)

            // 3) 결과 반영.
            // TODO(KAN-48): response.accessToken / response.refreshToken을 KeyChain에 저장.
            isNewUser = response.isNewUser
            didSignInSucceed = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Kakao SDK bridge (KAN-47 에서 대체)

    /// Kakao SDK로부터 `kakaoAccessToken`을 비동기적으로 획득하는 스텁.
    ///
    /// - Note: KAN-47 에서 Kakao iOS SDK를 도입하면서 실제 구현으로 교체한다.
    ///   본 메서드는 서비스(`AuthService`)가 SDK 의존성을 갖지 않도록 경계를 분리하는 역할이다.
    private func obtainKakaoAccessToken() async throws -> String {
        // TODO(KAN-47): Kakao SDK 로그인 플로우로 대체.
        throw AuthError.unknown(NSError(
            domain: "LoginViewModel",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Kakao SDK 미연동 (KAN-47)"]
        ))
    }
}
