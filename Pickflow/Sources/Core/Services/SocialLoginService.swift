import Foundation

final class SocialLoginService: SocialLoginServiceProtocol {
    private let authService: AuthServiceProtocol
    private let kakaoAuthProvider: KakaoAuthProviderProtocol
    private let appleAuthProvider: AppleAuthProviderProtocol
    private let tokenStore: TokenStoreProtocol

    init(
        authService: AuthServiceProtocol,
        kakaoAuthProvider: KakaoAuthProviderProtocol,
        appleAuthProvider: AppleAuthProviderProtocol,
        tokenStore: TokenStoreProtocol
    ) {
        self.authService = authService
        self.kakaoAuthProvider = kakaoAuthProvider
        self.appleAuthProvider = appleAuthProvider
        self.tokenStore = tokenStore
    }

    func signInWithKakao() async throws {
        let kakaoToken = try await kakaoAuthProvider.obtainAccessToken()
        let response = try await authService.signInWithKakao(kakaoAccessToken: kakaoToken)
        try tokenStore.save(AuthToken(accessToken: response.accessToken, refreshToken: response.refreshToken))
    }

    func signInWithApple() async throws {
        let credential = try await appleAuthProvider.obtainCredential()
        let response = try await authService.signInWithApple(
            identityToken: credential.identityToken,
            nonce: credential.nonce
        )
        try tokenStore.save(AuthToken(accessToken: response.accessToken, refreshToken: response.refreshToken))
    }
}
