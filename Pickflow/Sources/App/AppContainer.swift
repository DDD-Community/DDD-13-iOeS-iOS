import Foundation

@MainActor
final class AppContainer {
    static let shared = AppContainer()

    let container: DIContainer

    private init() {
        container = DIContainer()
        registerDependencies()
        DIContainerHolder.shared = container
    }

    private func registerDependencies() {
        container.register(NetworkManagerProtocol.self, scope: .container) { NetworkManager() }
        container.register(TokenStoreProtocol.self, scope: .container) { KeychainTokenStore() }

        let networkManager: NetworkManagerProtocol = container.resolve(NetworkManagerProtocol.self)!
        let tokenStore: TokenStoreProtocol = container.resolve(TokenStoreProtocol.self)!

        container.register(UserServiceProtocol.self) { UserService(networkManager: networkManager) }
        container.register(AuthServiceProtocol.self) { AuthService(networkManager: networkManager, tokenStore: tokenStore) }
        container.register(KakaoAuthProviderProtocol.self, scope: .container) { KakaoAuthProvider() }
        container.register(MapServiceProtocol.self) { MapService(networkManager: networkManager) }
        container.register(AddressServiceProtocol.self) { AddressService(networkManager: networkManager) }
        container.register(LocationServiceProtocol.self, scope: .container) { LocationService() }
    }
}
