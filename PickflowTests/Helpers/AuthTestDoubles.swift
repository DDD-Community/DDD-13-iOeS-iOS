import Foundation
@testable import Pickflow

final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    var kakaoResult: Result<TokenResponse, any Error> = .success(.fixture(provider: .kakao))
    var appleResult: Result<TokenResponse, any Error> = .success(.fixture(provider: .apple))
    private(set) var kakaoAccessTokens: [String] = []
    private(set) var appleRequests: [(identityToken: String, user: AppleUserInfo?)] = []

    func signInWithKakao(accessToken: String) async throws -> TokenResponse {
        kakaoAccessTokens.append(accessToken)
        return try kakaoResult.get()
    }

    func signInWithApple(identityToken: String, user: AppleUserInfo?) async throws -> TokenResponse {
        appleRequests.append((identityToken, user))
        return try appleResult.get()
    }

    func refreshToken(_: String) async throws -> AuthToken {
        AuthToken(accessToken: "refreshed-access", refreshToken: "refreshed-refresh")
    }

    func signOut() async throws {}

    func currentAuthState() async -> AuthState { .signedOut }
}

final class MockKakaoAuthProvider: KakaoAuthProviderProtocol, @unchecked Sendable {
    var result: Result<String, any Error> = .success("kakao-access-token")
    private(set) var callCount = 0

    func obtainAccessToken() async throws -> String {
        callCount += 1
        return try result.get()
    }
}

final class MockAppleAuthProvider: AppleAuthProviderProtocol, @unchecked Sendable {
    var result: Result<AppleCredential, any Error> = .success(
        AppleCredential(identityToken: "apple-identity-token", fullName: nil, email: nil)
    )
    private(set) var callCount = 0

    func obtainCredential() async throws -> AppleCredential {
        callCount += 1
        return try result.get()
    }
}

final class MockSocialLoginService: SocialLoginServiceProtocol, @unchecked Sendable {
    var kakaoError: (any Error)?
    var appleError: (any Error)?
    private(set) var kakaoCallCount = 0
    private(set) var appleCallCount = 0

    func signInWithKakao() async throws {
        kakaoCallCount += 1
        if let kakaoError { throw kakaoError }
    }

    func signInWithApple() async throws {
        appleCallCount += 1
        if let appleError { throw appleError }
    }
}

final class MockTokenStore: TokenStoreProtocol, @unchecked Sendable {
    var saveError: (any Error)?
    private(set) var savedTokens: [AuthToken] = []
    var storedToken: AuthToken?

    func save(_ token: AuthToken) throws {
        if let saveError { throw saveError }
        savedTokens.append(token)
        storedToken = token
    }

    func load() throws -> AuthToken? {
        storedToken
    }

    func clear() throws {
        storedToken = nil
    }
}

extension TokenResponse {
    static func fixture(provider: SocialProvider = .kakao) -> TokenResponse {
        TokenResponse(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            profile: UserProfile(
                userId: "123",
                email: "test@example.com",
                nickname: "tester",
                profileImageUrl: nil,
                provider: provider
            )
        )
    }
}
