import Foundation

@MainActor
final class AppContainer {
    static let shared = AppContainer()

    let container: DIContainer

    private init() {
        container = DIContainer()
        registerDependencies()
    }

    private func registerDependencies() {
        let networkManager = NetworkManager()

        container.register(NetworkManagerProtocol.self) { networkManager }
        container.register(UserServiceProtocol.self) { UserService(networkManager: networkManager) }
        container.register(AuthServiceProtocol.self) { AuthService(networkManager: networkManager) }
    }
}
