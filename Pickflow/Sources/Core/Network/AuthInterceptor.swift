import Alamofire
import Foundation

final class AuthInterceptor: RequestInterceptor, @unchecked Sendable {
    private let tokenStore: TokenStoreProtocol
    private var isRefreshing = false

    init(tokenStore: TokenStoreProtocol) {
        self.tokenStore = tokenStore
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping @Sendable (Result<URLRequest, any Error>) -> Void) {
        Task {
            var request = urlRequest
            if let token = try? tokenStore.load(), !token.accessToken.isEmpty {
                request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
            }
            completion(.success(request))
        }
    }

    func retry(_ request: Request, for session: Session, dueTo error: any Error, completion: @escaping @Sendable (RetryResult) -> Void) {
        guard
            let response = request.task?.response as? HTTPURLResponse,
            response.statusCode == 401,
            !isRefreshing
        else {
            completion(.doNotRetry)
            return
        }

        isRefreshing = true
        Task {
            defer { isRefreshing = false }
            guard
                let currentToken = try? tokenStore.load(),
                !currentToken.refreshToken.isEmpty
            else {
                completion(.doNotRetry)
                return
            }
            do {
                let newToken = try await callRefresh(currentToken.refreshToken)
                try tokenStore.save(newToken)
                completion(.retry)
            } catch {
                try? tokenStore.clear()
                completion(.doNotRetry)
            }
        }
    }

    // URLSession으로 직접 호출해 Alamofire Session과의 순환 참조를 방지
    private func callRefresh(_ refreshToken: String) async throws -> AuthToken {
        var urlRequest = URLRequest(url: URL(string: APIBaseURL.current + "/v1/auth/refresh")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(["refreshToken": refreshToken])

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AuthError.unauthorized
        }

        let decoded = try JSONDecoder().decode(ApiResponse<TokenResponse>.self, from: data)
        return AuthToken(
            accessToken: decoded.data.accessToken,
            refreshToken: decoded.data.refreshToken,
            userId: decoded.data.profile.userId
        )
    }
}
