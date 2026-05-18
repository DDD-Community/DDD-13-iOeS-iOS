import SwiftUI
import KakaoSDKAuth
import KakaoSDKCommon

@main
struct PickflowApp: App {
    private let container = AppContainer.shared

    init() {
        DesignSystemFontRegister.registerAllCustomFonts()
        initializeKakaoSDK()
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            // TODO: KAN-99 데모용 임시 루트 — 머지 전 AppRootView로 복구
            NavigationStack {
                ExploreHomeView()
            }
            #else
            AppRootView(
                authService: container.container.resolve(AuthServiceProtocol.self)!,
                kakaoAuthProvider: container.container.resolve(KakaoAuthProviderProtocol.self)!,
                appleAuthProvider: container.container.resolve(AppleAuthProviderProtocol.self)!,
                tokenStore: container.container.resolve(TokenStoreProtocol.self)!,
                locationService: container.container.resolve(LocationServiceProtocol.self)!,
                onboardingCompletionStore: container.container.resolve(OnboardingCompletionStore.self)!
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onOpenURL { url in
                if AuthApi.isKakaoTalkLoginUrl(url) {
                    _ = AuthController.handleOpenUrl(url: url)
                }
            }
            #endif
        }
    }

    private func initializeKakaoSDK() {
        guard let appKey = Bundle.main.object(forInfoDictionaryKey: "KAKAO_NATIVE_APP_KEY") as? String,
              appKey.isEmpty == false,
              appKey != "YOUR_KAKAO_NATIVE_APP_KEY"
        else {
            #if DEBUG
            print("Skipping KakaoSDK initialization: KAKAO_NATIVE_APP_KEY is missing or still using a placeholder value.")
            #endif
            return
        }

        KakaoSDK.initSDK(appKey: appKey)
    }
}
