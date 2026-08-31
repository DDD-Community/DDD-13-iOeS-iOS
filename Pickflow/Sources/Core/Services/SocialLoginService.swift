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
        let response = try await authService.signInWithKakao(accessToken: kakaoToken)
        try tokenStore.save(AuthToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            userId: response.profile.userId
        ))
    }

    func signInWithApple() async throws {
        let credential = try await appleAuthProvider.obtainCredential()
        let user = AppleUserInfo(
            firstName: credential.fullName?.givenName,
            lastName: credential.fullName?.familyName,
            email: credential.email
        )
        let response = try await authService.signInWithApple(
            identityToken: credential.identityToken,
            user: user
        )
        try tokenStore.save(AuthToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            userId: response.profile.userId
        ))
    }

    func restoreAccount(restoreToken: String) async throws {
        try await authService.restoreAccount(restoreToken: restoreToken)
    }

    func retrySignIn(with credential: ProviderCredential) async throws {
        let response: TokenResponse
        switch credential {
        case let .kakao(accessToken):
            response = try await authService.signInWithKakao(accessToken: accessToken)
        case let .apple(identityToken, user):
            response = try await authService.signInWithApple(identityToken: identityToken, user: user)
        }
        try tokenStore.save(AuthToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            userId: response.profile.userId
        ))
    }
}
