import Foundation
@testable import Pickflow

final class FakeReviewRequestStore: ReviewRequestStore, @unchecked Sendable {
    var hasRequestedValue: Bool = false
    private(set) var hasRequestedCallCount: Int = 0
    private(set) var markCallCount: Int = 0

    func hasRequestedReview() -> Bool {
        hasRequestedCallCount += 1
        return hasRequestedValue
    }

    func markReviewRequested() {
        markCallCount += 1
        hasRequestedValue = true
    }
}

final class SpyReviewRequestService: ReviewRequestServiceProtocol, @unchecked Sendable {
    /// requestReview() 가 반환할 값(활성 scene 존재 여부 시뮬레이션).
    var requestReviewResult: Bool = true
    private(set) var requestReviewCallCount: Int = 0

    @MainActor
    @discardableResult
    func requestReview() -> Bool {
        requestReviewCallCount += 1
        return requestReviewResult
    }
}

final class SpyAnalyticsLogger: AnalyticsLoggerProtocol, @unchecked Sendable {
    private(set) var loggedEventNames: [String] = []

    func log(_ event: AnalyticsEvent) {
        loggedEventNames.append(event.name)
    }
}
