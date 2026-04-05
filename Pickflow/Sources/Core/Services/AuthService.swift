import Foundation

final class AuthService: AuthServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func signIn(email: String, password: String) async throws -> AuthToken {
        // TODO: Implement with actual endpoint
        fatalError("Not implemented")
    }

    func signOut() async throws {
        // TODO: Implement
        fatalError("Not implemented")
    }
}
