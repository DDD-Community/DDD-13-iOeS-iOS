import ProjectDescription

let project = Project(
    name: "Pickflow",
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
            "SDKROOT": "iphoneos",
        ],
        configurations: [
            .debug(name: "Debug", xcconfig: "Configs/Common.xcconfig"),
            .release(name: "Release", xcconfig: "Configs/Common.xcconfig"),
        ]
    ),
    targets: [
        .target(
            name: "Pickflow",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.pickflow",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "Pickflow",
                "FirebaseAppDelegateProxyEnabled": .boolean(false),
                "FirebaseMessagingAutoInitEnabled": .boolean(true),
                "KAKAO_NATIVE_APP_KEY": "$(KAKAO_NATIVE_APP_KEY)",
                "CFBundleURLTypes": [
                    [
                        "CFBundleTypeRole": "Editor",
                        "CFBundleURLName": "$(PRODUCT_BUNDLE_IDENTIFIER)",
                        "CFBundleURLSchemes": ["$(KAKAO_CALLBACK_SCHEME)"],
                    ],
                ],
                "LSApplicationQueriesSchemes": [
                    "kakaokompassauth",
                ],
                "NMFNcpKeyId": "$(NAVER_MAPS_CLIENT_ID)",
                "UILaunchScreen": [
                    "UIColorName": "",
                    "UIImageName": "",
                ],
                "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
            ]),
            sources: ["Pickflow/Sources/**"],
            resources: [
                "Pickflow/Resources/**",
                "Configs/GoogleService-Info.plist",
            ],
            dependencies: [
                .external(name: "Alamofire"),
                .external(name: "FirebaseMessaging"),
                .external(name: "KakaoSDKCommon"),
                .external(name: "KakaoSDKAuth"),
                .external(name: "KakaoSDKUser"),
                .external(name: "NMapsMap"),
                .external(name: "Swinject"),
            ],
            settings: .settings(
                base: [
                    "SWIFT_STRICT_CONCURRENCY": "complete",
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "4DUZKVXU2R",
                    "OTHER_LDFLAGS": .array(["$(inherited)", "-ObjC"]),
                ]
            )
        ),
    ]
)
