import Alamofire
import Foundation

protocol AccessTokenProvider: Sendable {
    func accessToken() async -> String?
}

struct EmptyAccessTokenProvider: AccessTokenProvider {
    func accessToken() async -> String? { nil }
}

final class AuthInterceptor: RequestInterceptor, @unchecked Sendable {
    private let tokenProvider: any AccessTokenProvider

    init(tokenProvider: any AccessTokenProvider = EmptyAccessTokenProvider()) {
        self.tokenProvider = tokenProvider
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping @Sendable (Result<URLRequest, any Error>) -> Void) {
        Task {
            var request = urlRequest
            if let token = await tokenProvider.accessToken(), !token.isEmpty {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            completion(.success(request))
        }
    }

    func retry(_ request: Request, for session: Session, dueTo error: any Error, completion: @escaping @Sendable (RetryResult) -> Void) {
        // Refresh token flow is intentionally left for the auth follow-up.
        completion(.doNotRetry)
    }
}
