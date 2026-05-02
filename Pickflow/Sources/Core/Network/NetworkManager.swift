import Alamofire
import Foundation

protocol NetworkManagerProtocol: Sendable {
    /// 기본 요청. URL-encoded 쿼리/폼 파라미터를 사용한다.
    func request<T: Decodable & Sendable>(endpoint: any APIEndpoint) async throws -> T

    /// JSON Body 요청. POST/PUT/PATCH에서 `application/json` 바디가 필요할 때 사용한다.
    /// 응답은 snake_case ↔ camelCase 자동 매핑.
    func requestJSON<T: Decodable & Sendable>(endpoint: any APIEndpoint) async throws -> T
}

final class NetworkManager: NetworkManagerProtocol, Sendable {
    private let session: Session

    init(session: Session = .default) {
        self.session = session
    }

    func request<T: Decodable & Sendable>(endpoint: any APIEndpoint) async throws -> T {
        try await session.request(
            endpoint.url,
            method: endpoint.method,
            parameters: endpoint.parameters,
            headers: endpoint.headers
        )
        .serializingDecodable(T.self, decoder: Self.snakeCaseDecoder)
        .value
    }

    func requestJSON<T: Decodable & Sendable>(endpoint: any APIEndpoint) async throws -> T {
        try await session.request(
            endpoint.url,
            method: endpoint.method,
            parameters: endpoint.parameters,
            encoding: JSONEncoding.default,
            headers: endpoint.headers
        )
        .serializingDecodable(T.self, decoder: Self.snakeCaseDecoder)
        .value
    }

    // MARK: - Helpers

    private static let snakeCaseDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}
