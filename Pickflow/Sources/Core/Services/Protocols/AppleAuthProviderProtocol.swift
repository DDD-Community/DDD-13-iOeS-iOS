import Foundation

struct AppleCredential: Sendable, Equatable {
    let identityToken: String
    let nonce: String
}

protocol AppleAuthProviderProtocol: Sendable {
    func obtainCredential() async throws -> AppleCredential
}

@MainActor
func getAppleAuthProvider() -> AppleAuthProviderProtocol {
    guard let provider = DIContainerHolder.shared?.resolve(AppleAuthProviderProtocol.self) else {
        fatalError("AppleAuthProviderProtocol is not registered in DIContainer")
    }
    return provider
}
