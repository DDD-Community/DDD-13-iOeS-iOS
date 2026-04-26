import Alamofire
import Foundation

protocol NetworkManagerProtocol: Sendable {
    func request<T: Decodable & Sendable>(endpoint: any APIEndpoint) async throws -> T
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
}
