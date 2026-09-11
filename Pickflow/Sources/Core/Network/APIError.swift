import Foundation

struct APIError: Error, LocalizedError, Sendable {
    let code: String
    let message: String
    /// 응답의 HTTP 상태 코드. 서버 에러 바디를 우선 파싱하면서도
    /// 상태 코드로 분기하던 기존 로직(AuthService 등)을 유지하기 위해 함께 보관한다.
    let statusCode: Int?

    init(code: String, message: String, statusCode: Int? = nil) {
        self.code = code
        self.message = message
        self.statusCode = statusCode
    }

    var errorDescription: String? { message }

    func post() {
        NotificationCenter.default.post(name: .apiError, object: self)
    }
}

extension Notification.Name {
    static let apiError = Notification.Name("APIError")
}
