import ProjectDescription

public enum URLScheme {
    public static let editorRole = "Editor"
    public static let kakaoCompassAuth = "kakaokompassauth"
    public static let portrait = "UIInterfaceOrientationPortrait"
}

public extension InfoPlist {
    static let app: Self = .extendingDefault(with: [
        "CFBundleDisplayName": .string(ProjectEnvironment.name),
        "FirebaseAppDelegateProxyEnabled": .boolean(false),
        "FirebaseMessagingAutoInitEnabled": .boolean(true),
        "KAKAO_NATIVE_APP_KEY": .string("$(KAKAO_NATIVE_APP_KEY)"),
        "CFBundleURLTypes": .array([
            .dictionary([
                "CFBundleTypeRole": .string(URLScheme.editorRole),
                "CFBundleURLName": .string("$(PRODUCT_BUNDLE_IDENTIFIER)"),
                "CFBundleURLSchemes": .array([
                    .string("$(KAKAO_CALLBACK_SCHEME)"),
                ]),
            ]),
        ]),
        "LSApplicationQueriesSchemes": .array([
            .string(URLScheme.kakaoCompassAuth),
        ]),
        "NMFNcpKeyId": .string("$(NAVER_MAPS_CLIENT_ID)"),
        "UILaunchScreen": .dictionary([
            "UIColorName": .string(""),
            "UIImageName": .string(""),
        ]),
        "UISupportedInterfaceOrientations": .array([
            .string(URLScheme.portrait),
        ]),
    ])
}
