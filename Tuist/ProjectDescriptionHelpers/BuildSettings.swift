import ProjectDescription

public extension Configuration {
    static let appDebug = Self.debug(
        name: .debug,
        xcconfig: "Configs/Common.xcconfig"
    )

    static let appRelease = Self.release(
        name: .release,
        xcconfig: "Configs/Common.xcconfig"
    )
}

public extension SettingsDictionary {
    static let projectBase: Self = [
        "SWIFT_VERSION": .string("6.0"),
        "IPHONEOS_DEPLOYMENT_TARGET": .string(ProjectEnvironment.deploymentTarget),
        "SDKROOT": .string("iphoneos"),
    ]
}
