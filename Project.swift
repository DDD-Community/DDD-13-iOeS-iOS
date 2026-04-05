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
            .debug(name: "Debug"),
            .release(name: "Release"),
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
                "UILaunchScreen": [
                    "UIColorName": "",
                    "UIImageName": "",
                ],
                "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
            ]),
            sources: ["Pickflow/Sources/**"],
            resources: ["Pickflow/Resources/**"],
            dependencies: [
                .external(name: "Alamofire"),
                .external(name: "Swinject"),
            ],
            settings: .settings(
                base: [
                    "SWIFT_STRICT_CONCURRENCY": "complete",
                    "CODE_SIGN_STYLE": "Automatic",
                    "DEVELOPMENT_TEAM": "4DUZKVXU2R",
                ]
            )
        ),
    ]
)
