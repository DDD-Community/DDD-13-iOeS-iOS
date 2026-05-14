import Foundation

final class UserService: UserServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func fetchCurrentUser() async throws -> User {
        return try await networkManager.requestJSON(endpoint: UserEndpoint.me)
    }

    func updateProfile(nickname: String?, profileImageURL: URL?) async throws -> User {
        return try await networkManager.requestJSON(
            endpoint: UserEndpoint.updateProfile(nickname: nickname, profileImageURL: profileImageURL)
        )
    }

    func deleteAccount(reason: String, otherFeedback: String?) async throws {
        let _: EmptyResponse = try await networkManager.requestJSON(
            endpoint: UserEndpoint.deleteAccount(reason: reason, otherFeedback: otherFeedback)
        )
    }
}
