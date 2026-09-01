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
        container.register(TokenStoreProtocol.self, scope: .container) { KeychainTokenStore() }

        let tokenStore: TokenStoreProtocol = container.resolve(TokenStoreProtocol.self)!
        container.register(NetworkManagerProtocol.self, scope: .container) {
            NetworkManager(interceptor: AuthInterceptor(tokenStore: tokenStore))
        }

        let networkManager: NetworkManagerProtocol = container.resolve(NetworkManagerProtocol.self)!

        container.register(UserServiceProtocol.self) { UserService(networkManager: networkManager) }
        container.register(AppVersionServiceProtocol.self) { AppVersionService(networkManager: networkManager) }
        container.register(AuthServiceProtocol.self) { AuthService(networkManager: networkManager, tokenStore: tokenStore) }
        container.register(KakaoAuthProviderProtocol.self, scope: .container) { KakaoAuthProvider() }
        container.register(AppleAuthProviderProtocol.self, scope: .container) { AppleAuthProvider() }
        container.register(MapServiceProtocol.self) { MapService(networkManager: networkManager) }
        container.register(AddressServiceProtocol.self) { AddressService(networkManager: networkManager) }
        container.register(SpotServiceProtocol.self) { SpotService(networkManager: networkManager) }
        container.register(MySpotServiceProtocol.self) { MySpotService(networkManager: networkManager) }
        container.register(SpotListServiceProtocol.self) { SpotListService(networkManager: networkManager) }
        container.register(ArchiveServiceProtocol.self) { ArchiveService(networkManager: networkManager) }
        container.register(ClusteringServiceProtocol.self) { ClusteringService(networkManager: networkManager) }
        container.register(BookmarkServiceProtocol.self) { BookmarkService(networkManager: networkManager) }
        container.register(NoticeServiceProtocol.self) { NoticeService(networkManager: networkManager) }
        container.register(ShareIntentServiceProtocol.self) { ShareIntentService(networkManager: networkManager) }
        container.register(LocationServiceProtocol.self, scope: .container) { LocationService() }
        container.register(ExternalAppLauncherProtocol.self, scope: .container) { ExternalAppLauncher() }
        container.register(ShareSheetPresenterProtocol.self, scope: .container) { ShareSheetPresenter() }
        container.register(SocialLoginServiceProtocol.self, scope: .container) { [container] in
            SocialLoginService(
                authService: container.resolve(AuthServiceProtocol.self)!,
                kakaoAuthProvider: container.resolve(KakaoAuthProviderProtocol.self)!,
                appleAuthProvider: container.resolve(AppleAuthProviderProtocol.self)!,
                tokenStore: container.resolve(TokenStoreProtocol.self)!
            )
        }
        container.register(AnalyticsLoggerProtocol.self, scope: .container) { FirebaseAnalyticsLogger() }
        container.register(CrashReporterProtocol.self, scope: .container) { FirebaseCrashlyticsReporter() }
        container.register(OnboardingCompletionStore.self, scope: .container) { UserDefaultsOnboardingCompletionStore() }
        container.register(GuestModeStore.self, scope: .container) { UserDefaultsGuestModeStore() }
        container.register(ReviewRequestStore.self, scope: .container) { UserDefaultsReviewRequestStore() }
        container.register(ReviewRequestServiceProtocol.self, scope: .container) { ReviewRequestService() }
    }
}
