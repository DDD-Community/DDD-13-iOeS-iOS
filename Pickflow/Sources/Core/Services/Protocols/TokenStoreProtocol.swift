import Foundation

protocol TokenStoreProtocol: Sendable {
    func save(_ token: AuthToken) throws
    func load() throws -> AuthToken?
    func clear() throws
}

@MainActor
func getTokenStore() -> TokenStoreProtocol {
    guard let tokenStore = DIContainerHolder.shared?.resolve(TokenStoreProtocol.self) else {
        fatalError("TokenStoreProtocol is not registered in DIContainer")
    }
    return tokenStore
}
