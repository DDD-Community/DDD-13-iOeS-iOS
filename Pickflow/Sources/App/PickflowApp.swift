import SwiftUI
import FirebaseCore
import KakaoSDKAuth
import KakaoSDKCommon

@main
struct PickflowApp: App {
    private let container = AppContainer.shared
    @StateObject private var deepLinkRouter = DeepLinkRouter()

    init() {
        configureFirebase()
        DesignSystemFontRegister.registerAllCustomFonts()
        initializeKakaoSDK()
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if NoticeDemoFlag.isOn {
                NavigationStack {
                    NoticeListView(viewModel: NoticeListViewModel(noticeService: getNoticeService()))
                }
            } else {
                appRoot
            }
            #else
            appRoot
            #endif
        }
    }

    @ViewBuilder
    private var appRoot: some View {
        AppRootView(
            authService: getAuthService(),
            socialLoginService: getSocialLoginService(),
            locationService: getLocationService(),
            onboardingCompletionStore: getOnboardingCompletionStore()
        )
        .environmentObject(deepLinkRouter)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onOpenURL { url in
            if AuthApi.isKakaoTalkLoginUrl(url) {
                _ = AuthController.handleOpenUrl(url: url)
                return
            }
            handleUniversalLink(url)
        }
    }

    private func handleUniversalLink(_ url: URL) {
        guard url.host == "pickflow-api.us",
              url.pathComponents.count == 2,
              let spotId = SpotIDCoder.decodeSpot(url.pathComponents[1]) else { return }
        deepLinkRouter.pendingSpotId = spotId
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
