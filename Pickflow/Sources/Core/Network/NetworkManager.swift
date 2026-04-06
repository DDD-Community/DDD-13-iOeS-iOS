import Alamofire
import Foundation

protocol NetworkManagerProtocol: Sendable {
    func request<T: Decodable & Sendable>(endpoint: any APIEndpoint) async throws -> T
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
        .serializingDecodable(T.self)
        .value
    }
}
