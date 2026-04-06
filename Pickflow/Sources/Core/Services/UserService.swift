import Foundation

final class UserService: UserServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func fetchCurrentUser() async throws -> User {
        // TODO: Implement with actual endpoint
        fatalError("Not implemented")
    }
}
