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
                "Pickflow/Resources/**",
                "Configs/GoogleService-Info.plist",
            ],
            dependencies: [
                .external(.alamofire),
                .external(.firebaseMessaging),
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
    ]
)
