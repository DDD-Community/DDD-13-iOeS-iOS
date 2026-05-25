import SwiftUI
import FirebaseCore
import KakaoSDKAuth
import KakaoSDKCommon

@main
struct PickflowApp: App {
    private let container = AppContainer.shared

    init() {
        configureFirebase()
        DesignSystemFontRegister.registerAllCustomFonts()
        initializeKakaoSDK()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(
                authService: getAuthService(),
                socialLoginService: getSocialLoginService(),
                locationService: getLocationService(),
                onboardingCompletionStore: getOnboardingCompletionStore()
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onOpenURL { url in
                if AuthApi.isKakaoTalkLoginUrl(url) {
                    _ = AuthController.handleOpenUrl(url: url)
                }
            }
        }
    }

    private func configureFirebase() {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        FirebaseApp.configure()
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
