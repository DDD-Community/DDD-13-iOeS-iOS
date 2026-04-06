import Foundation

protocol AuthServiceProtocol: Sendable {
    func signIn(email: String, password: String) async throws -> AuthToken
    func signOut() async throws
}

struct AuthToken: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
}

@MainActor
func getAuthService() -> AuthServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(AuthServiceProtocol.self) else {
        fatalError("AuthServiceProtocol is not registered in DIContainer")
    }
    return service
}
