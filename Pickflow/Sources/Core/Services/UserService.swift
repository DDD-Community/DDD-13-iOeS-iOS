import Foundation

final class UserService: UserServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func fetchCurrentUser() async throws -> User {
        let response: ApiResponse<User> = try await networkManager.requestJSON(endpoint: UserEndpoint.me)
        return response.data
    }

    func updateProfile(nickname: String?, profileImageData: Data?) async throws -> User {
        let endpoint = UserEndpoint.updateProfile(nickname: nil)
        let _: EmptyResponse = try await networkManager.upload(endpoint: endpoint) { formData in
            if let nickname, let data = nickname.data(using: .utf8) {
                formData.append(data, withName: "nickname")
            }
            if let imageData = profileImageData {
                formData.append(imageData, withName: "profileImage", fileName: "profile.jpg", mimeType: "image/jpeg")
            }
        }
        return try await fetchCurrentUser()
    }

    func deleteAccount() async throws {
        let _: EmptyResponse = try await networkManager.request(endpoint: UserEndpoint.deleteAccount)
    }
}
