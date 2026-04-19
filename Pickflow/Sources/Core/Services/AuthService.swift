import Alamofire
import Foundation

final class AuthService: AuthServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
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
        do {
            let _: EmptyResponse = try await networkManager.requestJSON(
                endpoint: AuthEndpoint.logout
            )
        } catch {
            throw Self.map(error)
        }
    }

    func currentAuthState() async -> AuthState {
        // TODO(KAN-49): KeyChain(KAN-48)에 저장된 토큰을 조회하여 `.signedIn(token)` 반환.
        //               본 티켓(KAN-46)에서는 항상 `.signedOut`을 반환하는 스텁을 유지한다.
        .signedOut
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

// MARK: - EmptyResponse

/// 본문 없는 응답(예: 204 No Content) 디코딩용.
private struct EmptyResponse: Decodable, Sendable {}
