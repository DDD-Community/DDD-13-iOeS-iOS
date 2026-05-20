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
            rootView
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        // [KAN-91] PR 머지 시 삭제 예정 — -AnalyticsSample 런치 인자 분기 및 AnalyticsSampleView 진입
        #if DEBUG
        if CommandLine.arguments.contains("-AnalyticsSample") {
            AnalyticsSampleView()
        } else if CommandLine.arguments.contains("-debugMyProfileSignedIn") {
            MyProfileSignedInDebugView()
        } else if CommandLine.arguments.contains("-debugMyProfile") {
            MyProfileDebugView()
        } else if CommandLine.arguments.contains("-debugArchiveSignedIn") {
            ArchiveSignedInDebugView()
        } else if CommandLine.arguments.contains("-debugArchiveSignedOut") {
            ArchiveSignedOutDebugView()
        } else if CommandLine.arguments.contains("-debugArchiveEmpty") {
            ArchiveEmptyDebugView()
        } else {
            defaultRootView
        }
        #else
        defaultRootView
        #endif
    }

    private var defaultRootView: some View {
        AppRootView(
            authService: container.container.resolve(AuthServiceProtocol.self)!,
            socialLoginService: container.container.resolve(SocialLoginServiceProtocol.self)!,
            locationService: container.container.resolve(LocationServiceProtocol.self)!,
            onboardingCompletionStore: container.container.resolve(OnboardingCompletionStore.self)!
        )
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
