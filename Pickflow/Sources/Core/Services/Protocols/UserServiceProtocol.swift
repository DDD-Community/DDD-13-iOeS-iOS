import Foundation

protocol UserServiceProtocol: Sendable {
    func fetchCurrentUser() async throws -> User
}

struct User: Codable, Sendable {
    let id: String
    let name: String
    let email: String
}
