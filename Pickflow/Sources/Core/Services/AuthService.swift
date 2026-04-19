import Foundation

final class AuthService: AuthServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    // MARK: - AuthServiceProtocol
    // NOTE(KAN-46): 본 커밋(C1)에서는 프로토콜 시그니처만 맞추고, 실제 네트워크 호출은
    //              다음 커밋(C2)에서 `AuthEndpoint` 기반으로 구현한다.

    func signInWithKakao(kakaoAccessToken _: String) async throws -> KakaoSignInResponse {
        throw AuthError.unknown(NSError(
            domain: "AuthService",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "signInWithKakao not implemented (C2에서 연결)"]
        ))
    }

    func refreshToken(_: String) async throws -> AuthToken {
        throw AuthError.unknown(NSError(
            domain: "AuthService",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "refreshToken not implemented (C2에서 연결)"]
        ))
    }

    func signOut() async throws {
        throw AuthError.unknown(NSError(
            domain: "AuthService",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "signOut not implemented (C2에서 연결)"]
        ))
    }

    func currentAuthState() async -> AuthState {
        // TODO(KAN-49): KeyChain(KAN-48)에 저장된 토큰을 조회하여 `.signedIn` 반환.
        .signedOut
    }
}
