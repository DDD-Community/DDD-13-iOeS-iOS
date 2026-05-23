import Foundation
@testable import Pickflow

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

final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    var kakaoResult: Result<KakaoSignInResponse, any Error> = .success(.fixture(provider: .kakao))
    var appleResult: Result<AppleSignInResponse, any Error> = .success(.fixture(provider: .apple))
    private(set) var kakaoAccessTokens: [String] = []
    private(set) var appleRequests: [(identityToken: String, nonce: String)] = []

    func signInWithKakao(kakaoAccessToken: String) async throws -> KakaoSignInResponse {
        kakaoAccessTokens.append(kakaoAccessToken)
        return try kakaoResult.get()
    }

    func signInWithApple(identityToken: String, nonce: String) async throws -> AppleSignInResponse {
        appleRequests.append((identityToken, nonce))
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
        AppleCredential(identityToken: "apple-identity-token", nonce: "raw-nonce")
    )
    private(set) var callCount = 0

    func obtainCredential() async throws -> AppleCredential {
        callCount += 1
        return try result.get()
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

extension KakaoSignInResponse {
    static func fixture(provider: SocialProvider = .kakao) -> KakaoSignInResponse {
        KakaoSignInResponse(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            isNewUser: false,
            user: .fixture(provider: provider)
        )
    }
}

extension AppleSignInResponse {
    static func fixture(provider: SocialProvider = .apple) -> AppleSignInResponse {
        AppleSignInResponse(
            accessToken: "apple-access-token",
            refreshToken: "apple-refresh-token",
            isNewUser: false,
            user: .fixture(provider: provider)
        )
    }
}

extension AuthUser {
    static func fixture(provider: SocialProvider) -> AuthUser {
        AuthUser(id: 1, nickname: "tester", socialProvider: provider)
    }
}
