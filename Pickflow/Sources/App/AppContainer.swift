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
        let networkManager = NetworkManager()

        container.register(NetworkManagerProtocol.self) { networkManager }
        container.register(UserServiceProtocol.self) { UserService(networkManager: networkManager) }
        container.register(AuthServiceProtocol.self) { AuthService(networkManager: networkManager) }
        container.register(MapServiceProtocol.self) { MapService(networkManager: networkManager) }
        container.register(AddressServiceProtocol.self) { AddressService(networkManager: networkManager) }
    }
}
