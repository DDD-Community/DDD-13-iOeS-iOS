import Foundation

protocol UserServiceProtocol: Sendable {
    func fetchCurrentUser() async throws -> User
    func updateProfile(nickname: String?, profileImageData: Data?) async throws -> User
    func deleteAccount() async throws
}

struct User: Codable, Equatable, Sendable {
    let id: String
    let nickname: String
    let email: String
    let profileImageURL: URL?
    let linkedSocialProvider: SocialProvider
}

extension User {
    static func fixture(
        nickname: String = "capybara123",
        email: String = "test@example.com",
        profileImageURL: URL? = nil,
        linkedSocialProvider: SocialProvider = .kakao
    ) -> User {
        User(
            id: "user-1",
            nickname: nickname,
            email: email,
            profileImageURL: profileImageURL,
            linkedSocialProvider: linkedSocialProvider
        )
    }
}

@MainActor
func getUserService() -> UserServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(UserServiceProtocol.self) else {
        fatalError("UserServiceProtocol is not registered in DIContainer")
    }
    return service
}
