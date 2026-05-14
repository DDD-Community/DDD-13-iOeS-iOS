import Alamofire
import Foundation

final class AuthService: AuthServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol
    private let tokenStore: TokenStoreProtocol

    init(networkManager: NetworkManagerProtocol, tokenStore: TokenStoreProtocol) {
        self.networkManager = networkManager
        self.tokenStore = tokenStore
    }

    // MARK: - AuthServiceProtocol

    func signInWithKakao(kakaoAccessToken: String) async throws -> KakaoSignInResponse {
        do {
            return try await networkManager.requestJSON(
                endpoint: AuthEndpoint.kakaoSignIn(token: kakaoAccessToken)
            )
        } catch {
            throw Self.map(error)
        }
    }

    func signInWithApple(identityToken: String, nonce: String) async throws -> AppleSignInResponse {
        do {
            return try await networkManager.requestJSON(
                endpoint: AuthEndpoint.appleSignIn(identityToken: identityToken, nonce: nonce)
            )
        } catch {
            throw Self.map(error)
        }
    }

    func refreshToken(_ refreshToken: String) async throws -> AuthToken {
        do {
            return try await networkManager.requestJSON(
                endpoint: AuthEndpoint.refresh(refreshToken: refreshToken)
            )
        } catch {
            throw Self.map(error)
        }
    }

    func signOut() async throws {
        let storedToken = try? tokenStore.load()

        guard let refreshToken = storedToken?.refreshToken, refreshToken.isEmpty == false else {
            try? tokenStore.clear()
            return
        }

        do {
            let _: EmptyResponse = try await networkManager.requestJSON(
                endpoint: AuthEndpoint.logout(refreshToken: refreshToken)
            )
            try? tokenStore.clear()
        } catch {
            throw Self.map(error)
        }
    }

    func currentAuthState() async -> AuthState {
        do {
            if let token = try tokenStore.load() {
                return .signedIn(token)
            }
        } catch {
            try? tokenStore.clear()
        }

        return .signedOut
    }

    // MARK: - Error Mapping

    /// Alamofire/네트워크 에러를 앱 도메인 `AuthError`로 변환.
    private static func map(_ error: Error) -> AuthError {
        if let authError = error as? AuthError {
            return authError
        }
        if let afError = error as? AFError,
           let statusCode = afError.responseCode
        {
            switch statusCode {
            case 401: return .unauthorized
            case 403: return .forbidden
            case 422: return .validation
            case 502: return .external
            default: break
            }
        }
        return .unknown(error)
    }
}
