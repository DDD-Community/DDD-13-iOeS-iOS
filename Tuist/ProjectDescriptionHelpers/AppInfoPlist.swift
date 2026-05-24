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
        "FirebaseAppDelegateProxyEnabled": .boolean(false),
        "FirebaseMessagingAutoInitEnabled": .boolean(true),
        "KAKAO_NATIVE_APP_KEY": .string("$(KAKAO_NATIVE_APP_KEY)"),
        "NSLocationWhenInUseUsageDescription": .string("사용자의 현재 위치를 기반으로 정확한 포토스팟 정보를 제공하기 위해 위치 권한이 필요합니다."),
        "NSPhotoLibraryUsageDescription": .string("보관함 커버 이미지를 설정하기 위해 사진 접근 권한이 필요합니다."),
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
    ])
}
