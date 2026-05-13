import Foundation

protocol OnboardingCompletionStore: Sendable {
    func hasSeenOnboarding() -> Bool
    func markOnboardingSeen()
}

final class UserDefaultsOnboardingCompletionStore: OnboardingCompletionStore, @unchecked Sendable {
    private static let storageKey = "hasSeenOnboarding"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func hasSeenOnboarding() -> Bool {
        defaults.bool(forKey: Self.storageKey)
    }

    func markOnboardingSeen() {
        defaults.set(true, forKey: Self.storageKey)
    }
}

@MainActor
func getOnboardingCompletionStore() -> OnboardingCompletionStore {
    guard let store = DIContainerHolder.shared?.resolve(OnboardingCompletionStore.self) else {
        fatalError("OnboardingCompletionStore is not registered in DIContainer")
    }
    return store
}
