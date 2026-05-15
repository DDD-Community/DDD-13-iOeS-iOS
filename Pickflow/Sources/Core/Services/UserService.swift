import Foundation

final class UserService: UserServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func fetchCurrentUser() async throws -> User {
        return try await networkManager.requestJSON(endpoint: UserEndpoint.me)
    }

    func updateProfile(nickname: String?, profileImageData: Data?) async throws -> User {
        let endpoint = UserEndpoint.updateProfile(nickname: nickname)
        if let imageData = profileImageData {
            let _: EmptyResponse = try await networkManager.upload(endpoint: endpoint) { formData in
                formData.append(imageData, withName: "profileImage", fileName: "profile.jpg", mimeType: "image/jpeg")
            }
        } else {
            let _: EmptyResponse = try await networkManager.request(endpoint: endpoint)
        }
        return try await fetchCurrentUser()
    }

    func deleteAccount(reason: String, otherFeedback: String?) async throws {
        let _: EmptyResponse = try await networkManager.requestJSON(
            endpoint: UserEndpoint.deleteAccount(reason: reason, otherFeedback: otherFeedback)
        )
    }
}
