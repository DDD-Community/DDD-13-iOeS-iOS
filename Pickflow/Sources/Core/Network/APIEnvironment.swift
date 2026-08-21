import Foundation

/// API 서버 환경.
///
/// 기본값은 빌드 컨피그를 따른다 — Debug 는 dev, Release(TestFlight/App Store) 는 prod.
/// 운영 빌드에서도 숨은 진입점(마이 > 앱 버전 연속 탭 + 패스코드)으로 전환할 수 있어
/// 앱을 다시 말지 않고 QA 가 가능하다. 대신 아래 두 가지로 오조작을 막는다.
///
/// - 전환된 상태는 화면에 계속 표시된다 (마이 > 앱 버전 옆 `· dev`).
/// - 오버라이드는 **설치된 앱 버전에 묶인다.** 앱을 업데이트하면 자동으로 풀리므로,
///   전환해둔 걸 잊은 유저가 계속 dev 를 바라보는 상황이 이어지지 않는다.
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
    // 앱 버전 연동 해제 동작을 테스트에서 검증하기 위해 internal 로 둔다.
    static let overrideKey = "apiEnvironmentOverride"
    static let overrideAppVersionKey = "apiEnvironmentOverrideAppVersion"

    /// 빌드 컨피그가 정하는 기본 환경.
    static var buildDefault: APIEnvironment {
        #if DEBUG
        .dev
        #else
        .prod
        #endif
    }

    /// 우선순위: 실행 인자 > 저장된 오버라이드 > 빌드 기본값.
    static var current: APIEnvironment { launchArgumentOverride ?? storedOverride ?? buildDefault }

    /// 기본값과 다른 환경으로 전환된 상태인지. 화면에 표시해 두기 위해 쓴다.
    static var isOverridden: Bool { launchArgumentOverride != nil || storedOverride != nil }

    #if DEBUG
    /// Xcode 스킴 > Run > Arguments Passed On Launch 에 `-apiEnvironment dev` 를 넣어두면
    /// UI 를 거치지 않고 실행할 때마다 해당 환경으로 붙는다. 개발 중 전환이 가장 빠른 경로다.
    ///
    /// 정상 설치된 앱에는 실행 인자를 넣을 수 없으므로 일반 사용자에게 노출될 여지가 없고,
    /// Release 빌드에는 이 경로 자체가 컴파일되지 않는다.
    static let launchArgumentKey = "apiEnvironment"

    static var launchArgumentOverride: APIEnvironment? {
        let arguments = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
        guard let raw = arguments[launchArgumentKey] as? String else { return nil }
        return APIEnvironment(rawValue: raw)
    }
    #else
    static var launchArgumentOverride: APIEnvironment? { nil }
    #endif

    /// 저장된 오버라이드. 기록될 때의 앱 버전과 현재 앱 버전이 다르면 무시한다.
    private static var storedOverride: APIEnvironment? {
        let defaults = UserDefaults.standard
        guard let raw = defaults.string(forKey: overrideKey),
              let environment = APIEnvironment(rawValue: raw),
              defaults.string(forKey: overrideAppVersionKey) == currentAppVersion
        else {
            return nil
        }
        return environment
    }

    /// - Important: 서버가 바뀌면 기존 토큰은 반대편 서버에서 발급된 값이라 무효하다.
    ///   호출부에서 토큰을 비우고 앱 재시작을 안내해야 한다.
    static func setOverride(_ environment: APIEnvironment) {
        let defaults = UserDefaults.standard
        defaults.set(environment.rawValue, forKey: overrideKey)
        defaults.set(currentAppVersion, forKey: overrideAppVersionKey)
    }

    static func clearOverride() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: overrideKey)
        defaults.removeObject(forKey: overrideAppVersionKey)
    }

    static var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }
}

/// 숨은 진입점 규칙. 보안 장치가 아니라 **일반 유저가 실수로 들어가지 못하게 하는 속도 방지턱**이다.
enum APIEnvironmentUnlock {
    /// 마이 > 앱 버전 값을 연속으로 탭해야 하는 횟수.
    static let requiredTapCount = 7
    /// 이 시간 안에 연속으로 눌러야 카운트가 유지된다.
    static let tapWindow: TimeInterval = 3
    /// 팀 내 공유용 코드. 바이너리에 박히므로 비밀이 아니며, 오조작 방지 용도로만 쓴다.
    static let passcode = "1123"
}
