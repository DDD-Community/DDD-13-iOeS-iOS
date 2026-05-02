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
    private let decoder: JSONDecoder

    init(
        session: Session = Session(interceptor: AuthInterceptor()),
        decoder: JSONDecoder = .pickflow
    ) {
        self.session = session
        self.decoder = decoder
    }

    func request<T: Decodable & Sendable>(endpoint: any APIEndpoint) async throws -> T {
        let response = await session.request(
            endpoint.url,
            method: endpoint.method,
            parameters: endpoint.parameters,
            encoding: endpoint.encoding,
            headers: endpoint.headers
        )
        .validate()
        .serializingData()
        .response
        .serializingDecodable(T.self, decoder: Self.snakeCaseDecoder)
        .value

        if response.response?.statusCode == 409 {
            throw BookmarkError.alreadyBookmarked
        }

        if let error = response.error {
            throw error
        }

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        guard let data = response.data else {
            throw AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
        }

        return try decoder.decode(T.self, from: data)
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
