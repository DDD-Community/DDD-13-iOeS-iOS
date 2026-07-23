import StoreKit
import UIKit

/// 애플 공식 앱 평점 요청 시스템 팝업(`AppStore.requestReview`)을 띄운다.
/// 노출 여부/정책은 시스템이 관리하며, 클라이언트는 요청만 한다.
protocol ReviewRequestServiceProtocol: Sendable {
    /// 현재 활성 window scene에서 평점 요청 팝업을 띄운다.
    /// 실제로 팝업이 노출됐는지는 시스템이 결정한다(연 3회 제한 등).
    /// - Returns: 요청을 발동한 경우 `true`, 활성 scene을 찾지 못해 발동하지 못한 경우 `false`.
    @MainActor
    @discardableResult
    func requestReview() -> Bool
}

final class ReviewRequestService: ReviewRequestServiceProtocol, @unchecked Sendable {
    private let windowSceneProvider: @MainActor @Sendable () -> UIWindowScene?

    init(
        windowSceneProvider: @escaping @MainActor @Sendable () -> UIWindowScene? = { ReviewRequestService.activeWindowScene() }
    ) {
        self.windowSceneProvider = windowSceneProvider
    }

    @MainActor
    @discardableResult
    func requestReview() -> Bool {
        guard let scene = windowSceneProvider() else { return false }
        AppStore.requestReview(in: scene)
        return true
    }

    @MainActor
    private static func activeWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }
}

@MainActor
func getReviewRequestService() -> ReviewRequestServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(ReviewRequestServiceProtocol.self) else {
        fatalError("ReviewRequestServiceProtocol is not registered in DIContainer")
    }
    return service
}
