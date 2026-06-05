import Foundation

@MainActor
final class ForceUpdateViewModel: ObservableObject {
    /// 앱 시작 시 버전 정책 확인 상태.
    enum AppLaunchState: Equatable {
        /// 정책 확인 중.
        case checking
        /// 강제 업데이트 필요. 앱스토어 URL 동반.
        case needsForceUpdate(storeURL: URL)
        /// 앱 진입 허용.
        case available
    }

    @Published private(set) var state: AppLaunchState = .checking

    /// 강제 업데이트가 필요한 경우의 앱스토어 URL. 그 외엔 `nil`.
    var forceUpdateStoreURL: URL? {
        if case let .needsForceUpdate(storeURL) = state { return storeURL }
        return nil
    }

    /// 강제 업데이트 화면을 표시해야 하는지 여부.
    var isForceUpdateRequired: Bool { forceUpdateStoreURL != nil }

    private let service: AppVersionServiceProtocol
    private let currentVersion: String

    init(
        service: AppVersionServiceProtocol,
        currentVersion: String = Bundle.main.appVersion
    ) {
        self.service = service
        self.currentVersion = currentVersion
    }

    /// 서버 정책을 확인해 강제 업데이트 여부를 판정한다.
    ///
    /// 판단 기준: `현재 앱 버전 < minimumVersion && forceUpdate == true`.
    /// API 호출 실패 등 어떤 이유로든 판정이 불가하면 앱 진입을 허용한다(fail-open).
    func checkForUpdate() async {
        do {
            let policy = try await service.fetchIOSVersionPolicy()

            guard policy.forceUpdate,
                  let current = SemanticVersion(currentVersion),
                  let minimum = SemanticVersion(policy.minimumVersion),
                  current < minimum,
                  let storeURL = URL(string: policy.storeUrl) else {
                state = .available
                return
            }

            state = .needsForceUpdate(storeURL: storeURL)
        } catch {
            // 서버 장애로 모든 사용자의 앱 진입이 막히는 상황을 피하기 위해 진입을 허용한다.
            state = .available
        }
    }
}
