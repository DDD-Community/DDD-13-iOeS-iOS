import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: ProjectEnvironment.name,
    settings: .settings(
        base: .projectBase,
        configurations: [
            .appDebug,
            .appRelease,
        ]
    ),
    targets: [
        .target(
            name: ProjectEnvironment.name,
            destinations: [.iPhone],
            product: .app,
            bundleId: ProjectEnvironment.bundleID,
            deploymentTargets: .iOS(ProjectEnvironment.deploymentTarget),
            infoPlist: .app,
            sources: ["Pickflow/Sources/**"],
            resources: [
                .glob(
                    pattern: "Pickflow/Resources/**",
                    excluding: ["Pickflow/Resources/Pickflow.entitlements"]
                ),
                "Configs/GoogleService-Info.plist",
            ],
            entitlements: .file(path: "Pickflow/Resources/Pickflow.entitlements"),
            dependencies: [
                .external(.alamofire),
                .external(.firebaseCore),
                .external(.firebaseMessaging),
                .external(.firebaseAnalytics),
                .external(.kakaoSDKCommon),
                .external(.kakaoSDKAuth),
                .external(.kakaoSDKUser),
                .external(.nMapsMap),
                .external(.swinject),
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
        .target(
            name: "\(ProjectEnvironment.name)Tests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "\(ProjectEnvironment.bundleID).tests",
            deploymentTargets: .iOS(ProjectEnvironment.deploymentTarget),
            infoPlist: .default,
            sources: ["PickflowTests/**"],
            dependencies: [
                .target(name: ProjectEnvironment.name),
                .external(.snapshotTesting),
            ],
            settings: .settings(
                base: [
                    "SWIFT_STRICT_CONCURRENCY": "complete",
                ]
            )
        ),
    ]
)
