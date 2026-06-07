import Foundation

protocol UserServiceProtocol: Sendable {
    func fetchCurrentUser() async throws -> User
    func updateProfile(nickname: String?, profileImageData: Data?) async throws -> User
    func submitWithdrawalReason(reasonType: String, content: String?) async throws
    func deleteAccount() async throws
}

struct User: Codable, Equatable, Sendable {
    let nickname: String
    let profileImageUrl: String?
    let savedSpotCount: Int
    let recordedSpotCount: Int
    let provider: SocialProvider?
}

extension User {
    static func fixture(
        nickname: String = "capybara123",
        profileImageUrl: String? = nil,
        savedSpotCount: Int = 0,
        recordedSpotCount: Int = 0,
        provider: SocialProvider? = .kakao
    ) -> User {
        User(
            nickname: nickname,
            profileImageUrl: profileImageUrl,
            savedSpotCount: savedSpotCount,
            recordedSpotCount: recordedSpotCount,
            provider: provider
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
