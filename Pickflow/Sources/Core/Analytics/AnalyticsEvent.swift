import Foundation

protocol AnalyticsEvent {
    var name: String { get }
    var parameters: [String: Any]? { get }
}

extension AnalyticsEvent {
    var parameters: [String: Any]? { nil }
}
