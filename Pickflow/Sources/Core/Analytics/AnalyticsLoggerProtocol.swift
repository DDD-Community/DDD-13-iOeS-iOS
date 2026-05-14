import Foundation

protocol AnalyticsLoggerProtocol: Sendable {
    func log(_ event: AnalyticsEvent)
}

@MainActor
func getAnalyticsLogger() -> AnalyticsLoggerProtocol {
    guard let logger = DIContainerHolder.shared?.resolve(AnalyticsLoggerProtocol.self) else {
        fatalError("AnalyticsLoggerProtocol is not registered in DIContainer")
    }
    return logger
}
