import Foundation
import FirebaseAnalytics

final class FirebaseAnalyticsLogger: AnalyticsLoggerProtocol, @unchecked Sendable {
    func log(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }
}
