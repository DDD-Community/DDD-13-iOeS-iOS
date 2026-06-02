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
            scripts: [
                .post(
                    script: "\"${SRCROOT}/Tuist/.build/checkouts/firebase-ios-sdk/Crashlytics/run\"",
                    name: "Upload dSYMs to Crashlytics",
                    inputPaths: [
                        "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}",
                        "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}",
                        "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist",
                        "$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist",
                        "$(TARGET_BUILD_DIR)/$(EXECUTABLE_PATH)",
                    ]
                ),
            ],
            dependencies: [
                .external(.alamofire),
                .external(.firebaseCore),
                .external(.firebaseMessaging),
                .external(.firebaseAnalytics),
                .external(.firebaseCrashlytics),
                .external(.kakaoSDKCommon),
                .external(.kakaoSDKAuth),
                .external(.kakaoSDKUser),
                .external(.nMapsMap),
                .external(.swinject),
            ],
            settings: .settings(
                base: [
                    "SWIFT_STRICT_CONCURRENCY": "complete",
                    "CODE_SIGN_STYLE": "Manual",
                    "DEVELOPMENT_TEAM": "4DUZKVXU2R",
                    "CODE_SIGN_IDENTITY": "Apple Distribution",
                    "PROVISIONING_PROFILE_SPECIFIER": "$(PROVISIONING_PROFILE_SPECIFIER)",
                    "OTHER_LDFLAGS": .array(["$(inherited)", "-ObjC"]),
                    "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
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
