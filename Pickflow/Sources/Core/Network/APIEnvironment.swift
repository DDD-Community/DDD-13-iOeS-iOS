import Foundation

/// API 서버 환경.
///
/// 기본값은 빌드 컨피그를 따른다 — Debug 는 dev, Release(TestFlight/App Store) 는 prod.
/// Debug 빌드에 한해 런타임으로 바꿀 수 있고, 그 선택은 앱을 재시작해도 유지된다.
/// Release 빌드에는 오버라이드 경로 자체가 컴파일되지 않으므로 운영 빌드가 dev 를 볼 일은 없다.
enum APIEnvironment: String, CaseIterable, Sendable {
    case dev
    case prod

    var host: String {
        switch self {
        case .dev: "dev-api.pickflow-api.us"
        case .prod: "pickflow-api.us"
        }
    }

    var baseURL: String { "https://\(host)/api" }

    var displayName: String {
        switch self {
        case .dev: "개발 (dev)"
        case .prod: "운영 (prod)"
        }
    }
}

extension APIEnvironment {
    /// 빌드 컨피그가 정하는 기본 환경.
    static var buildDefault: APIEnvironment {
        #if DEBUG
        .dev
        #else
        .prod
        #endif
    }

    #if DEBUG
    private static let overrideKey = "debug.apiEnvironmentOverride"

    static var current: APIEnvironment {
        UserDefaults.standard.string(forKey: overrideKey)
            .flatMap(APIEnvironment.init(rawValue:)) ?? buildDefault
    }

    /// Debug 빌드 전용. 서버가 바뀌면 기존 토큰은 다른 서버에서 발급된 값이라 무효하므로,
    /// 호출부에서 토큰을 비우고 앱을 재시작해야 한다.
    static func setOverride(_ environment: APIEnvironment) {
        UserDefaults.standard.set(environment.rawValue, forKey: overrideKey)
    }

    static func clearOverride() {
        UserDefaults.standard.removeObject(forKey: overrideKey)
    }
    #else
    static var current: APIEnvironment { buildDefault }
    #endif
}
