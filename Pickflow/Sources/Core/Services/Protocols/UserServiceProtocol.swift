import Foundation

protocol UserServiceProtocol: Sendable {
    func fetchCurrentUser() async throws -> User
}

struct User: Codable, Sendable {
    let id: String
    let name: String
    let email: String
}

@MainActor
func getUserService() -> UserServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(UserServiceProtocol.self) else {
        fatalError("UserServiceProtocol is not registered in DIContainer")
    }
    return service
}
