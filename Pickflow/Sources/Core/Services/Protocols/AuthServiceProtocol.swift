import Foundation

protocol AuthServiceProtocol: Sendable {
    func signInWithKakao(accessToken: String) async throws -> TokenResponse
    func signInWithApple(identityToken: String, user: AppleUserInfo?) async throws -> TokenResponse
    func refreshToken(_ refreshToken: String) async throws -> AuthToken
    func signOut() async throws
    func currentAuthState() async -> AuthState
    func restoreAccount(restoreToken: String) async throws
}

@MainActor
func getAuthService() -> AuthServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(AuthServiceProtocol.self) else {
        fatalError("AuthServiceProtocol is not registered in DIContainer")
    }
    return service
}
