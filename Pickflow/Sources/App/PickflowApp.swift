import SwiftUI
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
            ContentView()
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
