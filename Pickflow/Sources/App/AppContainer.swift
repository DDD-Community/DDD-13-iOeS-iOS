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
        container.register(AppleAuthProviderProtocol.self, scope: .container) { AppleAuthProvider() }
        container.register(MapServiceProtocol.self) { MapService(networkManager: networkManager) }
        container.register(AddressServiceProtocol.self) { AddressService(networkManager: networkManager) }
        container.register(SpotServiceProtocol.self) { SpotService(networkManager: networkManager) }
        // FIXME(KAN-52 임시): BE 미오픈 — Mock 사용. BE 오픈 시 아래로 되돌릴 것.
        // container.register(SpotListServiceProtocol.self) { SpotListService(networkManager: networkManager) }
        container.register(SpotListServiceProtocol.self) { SpotListMockService() }
        container.register(ClusteringServiceProtocol.self) { ClusteringService(networkManager: networkManager) }
        container.register(BookmarkServiceProtocol.self) { BookmarkService(networkManager: networkManager) }
        container.register(ShareIntentServiceProtocol.self) { ShareIntentService(networkManager: networkManager) }
        container.register(LocationServiceProtocol.self, scope: .container) { LocationService() }
        container.register(ExternalAppLauncherProtocol.self, scope: .container) { ExternalAppLauncher() }
        container.register(ShareSheetPresenterProtocol.self, scope: .container) { ShareSheetPresenter() }
        container.register(AnalyticsLoggerProtocol.self, scope: .container) { FirebaseAnalyticsLogger() }
        container.register(OnboardingCompletionStore.self, scope: .container) { UserDefaultsOnboardingCompletionStore() }
    }
}
