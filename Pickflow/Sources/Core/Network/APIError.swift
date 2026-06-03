import Foundation

struct APIError: Error, LocalizedError, Sendable {
    let code: String
    let message: String

    var errorDescription: String? { message }

    func post() {
        NotificationCenter.default.post(name: .apiError, object: self)
    }
}

extension Notification.Name {
    static let apiError = Notification.Name("APIError")
}
