import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var didSignInSucceed = false
    @Published private(set) var isNewUser = false

    private let authService: AuthServiceProtocol
    private let kakaoAuthProvider: KakaoAuthProviderProtocol
    private let tokenStore: TokenStoreProtocol

    init(
        authService: AuthServiceProtocol,
        kakaoAuthProvider: KakaoAuthProviderProtocol,
        tokenStore: TokenStoreProtocol
    ) {
        self.authService = authService
        self.kakaoAuthProvider = kakaoAuthProvider
        self.tokenStore = tokenStore
    }

    // MARK: - Intent

    func signInWithKakaoTapped() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            // 1) Kakao SDK로 kakaoAccessToken 획득.
            let kakaoAccessToken = try await kakaoAuthProvider.obtainAccessToken()

            // 2) 백엔드 POST /auth/kakao 호출.
            let response = try await authService.signInWithKakao(kakaoAccessToken: kakaoAccessToken)

            // 3) 결과 반영.
            let authToken = AuthToken(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
            try tokenStore.save(authToken)
            isNewUser = response.isNewUser
            didSignInSucceed = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
