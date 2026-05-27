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

    func signInWithKakao(accessToken: String) async throws -> TokenResponse {
        do {
            let data = try await networkManager.requestJSONData(endpoint: AuthEndpoint.kakaoSignIn(accessToken: accessToken))
            if let failure = try? Self.snakeCaseDecoder.decode(LoginFailureResponse.self, from: data),
               failure.code == "U007",
               let restoreToken = failure.data?.restoreToken
            {
                throw AuthError.withdrawalRestoreRequired(restoreToken: restoreToken, credential: .kakao(accessToken: accessToken))
            }
            let response = try Self.snakeCaseDecoder.decode(ApiResponse<TokenResponse>.self, from: data)
            return response.data
        } catch {
            throw Self.map(error)
        }
    }

    func signInWithApple(identityToken: String, user: AppleUserInfo?) async throws -> TokenResponse {
        do {
            let data = try await networkManager.requestJSONData(endpoint: AuthEndpoint.appleSignIn(identityToken: identityToken, user: user))
            if let failure = try? Self.snakeCaseDecoder.decode(LoginFailureResponse.self, from: data),
               failure.code == "U007",
               let restoreToken = failure.data?.restoreToken
            {
                throw AuthError.withdrawalRestoreRequired(restoreToken: restoreToken, credential: .apple(identityToken: identityToken, user: user))
            }
            let response = try Self.snakeCaseDecoder.decode(ApiResponse<TokenResponse>.self, from: data)
            return response.data
        } catch {
            throw Self.map(error)
        }
    }

    func restoreAccount(restoreToken: String) async throws {
        do {
            let _: EmptyResponse = try await networkManager.request(
                endpoint: AuthEndpoint.restoreAccount(restoreToken: restoreToken)
            )
        } catch {
            throw Self.map(error)
        }
    }

    func refreshToken(_ refreshToken: String) async throws -> AuthToken {
        do {
            let response: ApiResponse<TokenResponse> = try await networkManager.requestJSON(
                endpoint: AuthEndpoint.refresh(refreshToken: refreshToken)
            )
            return AuthToken(accessToken: response.data.accessToken, refreshToken: response.data.refreshToken)
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

    // MARK: - Helpers

    private static let snakeCaseDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: - Error Mapping

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
