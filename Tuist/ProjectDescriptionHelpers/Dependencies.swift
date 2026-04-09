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
    case firebaseMessaging = "FirebaseMessaging"
    case nMapsMap = "NMapsMap"
    case swinject = "Swinject"

    public var name: String {
        rawValue
    }
}
