import ProjectDescription

public enum URLScheme {
    public static let editorRole = "Editor"
    public static let kakaoCompassAuth = "kakaokompassauth"
    public static let naverMap = "nmap"
    public static let portrait = "UIInterfaceOrientationPortrait"
}

extension InfoPlist {
    public static let app: Self = .extendingDefault(with: [
        "CFBundleDisplayName": .string(ProjectEnvironment.name),
        // Tuist 기본 Info.plist는 CFBundleShortVersionString을 리터럴 "1.0"으로 하드코딩하고,
        // archive 시 $(MARKETING_VERSION) 빌드 변수도 치환되지 않으므로, 실제 버전 문자열을 직접 박는다.
        // ProjectEnvironment.marketingVersion 을 단일 소스로 BuildSettings 와 함께 참조한다.
        // (CFBundleVersion(빌드넘버)은 fastlane agvtool 경로로 관리하므로 여기서 건드리지 않는다.)
        "CFBundleShortVersionString": .string(ProjectEnvironment.marketingVersion),
        "FirebaseAppDelegateProxyEnabled": .boolean(false),
        "FirebaseMessagingAutoInitEnabled": .boolean(true),
        "KAKAO_NATIVE_APP_KEY": .string("$(KAKAO_NATIVE_APP_KEY)"),
        "KAKAO_REST_API_KEY": .string("$(KAKAO_REST_API_KEY)"),
        "NSLocationWhenInUseUsageDescription": .string("사용자의 현재 위치를 기반으로 정확한 포토스팟 정보를 제공하기 위해 위치 권한이 필요합니다."),
        "NSPhotoLibraryUsageDescription": .string("보관함 커버 이미지를 설정하기 위해 사진 접근 권한이 필요합니다."),
        // 일부 접근(limited) 시 iOS 기본 자동 알림을 끄고, 앱 내 배너로 "사진 추가"를 제어한다.
        "PHPhotoLibraryPreventAutomaticLimitedAccessAlert": .boolean(true),
        "NSCameraUsageDescription": .string("프로필 사진 및 보관함 커버 이미지를 촬영하기 위해 카메라 접근 권한이 필요합니다."),
        "CFBundleURLTypes": .array([
            .dictionary([
                "CFBundleTypeRole": .string(URLScheme.editorRole),
                "CFBundleURLName": .string("$(PRODUCT_BUNDLE_IDENTIFIER)"),
                "CFBundleURLSchemes": .array([
                    .string("$(KAKAO_CALLBACK_SCHEME)")
                ]),
            ])
        ]),
        "LSApplicationQueriesSchemes": .array([
            .string(URLScheme.kakaoCompassAuth),
            .string(URLScheme.naverMap),
        ]),
        "NMFNcpKeyId": .string("$(NAVER_MAPS_CLIENT_ID)"),
        "UILaunchScreen": .dictionary([
            "UIColorName": .string(""),
            "UIImageName": .string(""),
        ]),
        "UISupportedInterfaceOrientations": .array([
            .string(URLScheme.portrait)
        ]),
        "UIUserInterfaceStyle": .string("Dark"),
        "ITSAppUsesNonExemptEncryption": .boolean(false),
    ])
}
