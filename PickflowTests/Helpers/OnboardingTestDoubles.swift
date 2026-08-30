import Foundation
@testable import Pickflow

final class MockOnboardingCompletionStore: OnboardingCompletionStore, @unchecked Sendable {
    var hasSeenValue: Bool = false
    private(set) var hasSeenCallCount: Int = 0
    private(set) var markCallCount: Int = 0

    func hasSeenOnboarding() -> Bool {
        hasSeenCallCount += 1
        return hasSeenValue
    }

    func markOnboardingSeen() {
        markCallCount += 1
        hasSeenValue = true
    }
}

final class MockGuestModeStore: GuestModeStore, @unchecked Sendable {
    var hasEnteredValue = false
    private(set) var markCallCount = 0

    func hasEnteredAsGuest() -> Bool {
        hasEnteredValue
    }

    func markGuestEntry() {
        markCallCount += 1
        hasEnteredValue = true
    }
}
