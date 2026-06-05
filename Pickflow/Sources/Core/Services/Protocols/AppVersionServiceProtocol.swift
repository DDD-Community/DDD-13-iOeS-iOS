import Foundation

protocol AppVersionServiceProtocol: Sendable {
    /// 서버에서 iOS 앱 버전 정책을 조회한다.
    func fetchIOSVersionPolicy() async throws -> AppVersionPolicy
}

@MainActor
func getAppVersionService() -> AppVersionServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(AppVersionServiceProtocol.self) else {
        fatalError("AppVersionServiceProtocol is not registered in DIContainer")
    }
    return service
}
