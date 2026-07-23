import Foundation

/// 앱스토어 평점 요청 시스템 팝업의 1회 노출 여부를 영속 저장한다.
/// 최초 스팟 등록 완료 시점에 단 한 번만 팝업이 발동되도록 제어하기 위한 플래그.
protocol ReviewRequestStore: Sendable {
    func hasRequestedReview() -> Bool
    func markReviewRequested()
}

final class UserDefaultsReviewRequestStore: ReviewRequestStore, @unchecked Sendable {
    private static let storageKey = "hasRequestedAppStoreReview"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func hasRequestedReview() -> Bool {
        defaults.bool(forKey: Self.storageKey)
    }

    func markReviewRequested() {
        defaults.set(true, forKey: Self.storageKey)
    }
}

@MainActor
func getReviewRequestStore() -> ReviewRequestStore {
    guard let store = DIContainerHolder.shared?.resolve(ReviewRequestStore.self) else {
        fatalError("ReviewRequestStore is not registered in DIContainer")
    }
    return store
}
