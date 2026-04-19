import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var didSignInSucceed = false
    @Published private(set) var isNewUser = false

    private let authService: AuthServiceProtocol
    private let kakaoAuthProvider: KakaoAuthProviderProtocol

    init(
        authService: AuthServiceProtocol,
        kakaoAuthProvider: KakaoAuthProviderProtocol
    ) {
        self.authService = authService
        self.kakaoAuthProvider = kakaoAuthProvider
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
            // TODO(KAN-48): response.accessToken / response.refreshToken을 KeyChain에 저장.
            isNewUser = response.isNewUser
            didSignInSucceed = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
