import Foundation

protocol AuthServiceProtocol: Sendable {
    func signIn(email: String, password: String) async throws -> AuthToken
    func signOut() async throws
}

struct AuthToken: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
}
