import ProjectDescription

public enum ProjectEnvironment {
    public static let name = "Pickflow"
    public static let bundleID = "com.pickflow"
    public static let developmentTeam = "4DUZKVXU2R"
    public static let deploymentTarget = "26.0"
    /// 앱 마케팅 버전(CFBundleShortVersionString)의 단일 소스.
    /// BuildSettings(MARKETING_VERSION)와 Info.plist가 모두 이 값을 참조한다.
    public static let marketingVersion = "1.1.0"
}
