import ProjectDescription

public extension TargetDependency {
    static func external(_ dependency: DoriDependency) -> TargetDependency {
        .external(name: dependency.name)
    }
}

public enum DoriDependency: String {
    case alamofire = "Alamofire"
    case kakaoSDKCommon = "KakaoSDKCommon"
    case kakaoSDKAuth = "KakaoSDKAuth"
    case kakaoSDKUser = "KakaoSDKUser"
    case firebaseCore = "FirebaseCore"
    case firebaseMessaging = "FirebaseMessaging"
    case firebaseAnalytics = "FirebaseAnalytics"
    case firebaseCrashlytics = "FirebaseCrashlytics"
    case nMapsMap = "NMapsMap"
    case snapshotTesting = "SnapshotTesting"
    case swinject = "Swinject"

    public var name: String {
        rawValue
    }
}
