import Alamofire
import Foundation

protocol NetworkManagerProtocol: Sendable {
    /// 기본 요청. URL-encoded 쿼리/폼 파라미터를 사용한다.
    func request<T: Decodable & Sendable>(endpoint: any APIEndpoint) async throws -> T

    /// JSON Body 요청. POST/PUT/PATCH에서 `application/json` 바디가 필요할 때 사용한다.
    /// 응답은 snake_case ↔ camelCase 자동 매핑.
    func requestJSON<T: Decodable & Sendable>(endpoint: any APIEndpoint) async throws -> T

    /// JSON Body 요청 후 raw Data 반환. 호출자가 직접 파싱이 필요할 때 사용한다.
    func requestJSONData(endpoint: any APIEndpoint) async throws -> Data

    /// Multipart form-data 업로드. 이미지/파일 전송 시 사용한다.
    func upload<T: Decodable & Sendable>(
        endpoint: any APIEndpoint,
        multipartFormData: @escaping @Sendable (MultipartFormData) -> Void
    ) async throws -> T
}

final class NetworkManager: NetworkManagerProtocol, Sendable {
    private let session: Session
    private let decoder: JSONDecoder

    init(
        interceptor: AuthInterceptor = AuthInterceptor(tokenStore: KeychainTokenStore()),
        decoder: JSONDecoder = .pickflow
    ) {
        #if DEBUG
        self.session = Session(interceptor: interceptor, eventMonitors: [ConsoleNetworkLogger()])
        #else
        self.session = Session(interceptor: interceptor)
        #endif
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

        guard let data = response.data else {
            throw AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
        }

        try Self.checkForAPIError(in: data)

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        return try decoder.decode(T.self, from: data)
    }

    func requestJSON<T: Decodable & Sendable>(endpoint: any APIEndpoint) async throws -> T {
        let data = try await session.request(
            endpoint.url,
            method: endpoint.method,
            parameters: endpoint.parameters,
            encoding: JSONEncoding.default,
            headers: endpoint.headers
        )
        .serializingData()
        .value

        try Self.checkForAPIError(in: data)
        return try Self.snakeCaseDecoder.decode(T.self, from: data)
    }

    func requestJSONData(endpoint: any APIEndpoint) async throws -> Data {
        let response = await session.request(
            endpoint.url,
            method: endpoint.method,
            parameters: endpoint.parameters,
            encoding: JSONEncoding.default,
            headers: endpoint.headers
        )
        .serializingData()
        .response

        if let error = response.error { throw error }
        guard let data = response.data else {
            throw AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
        }
        return data
    }

    func upload<T: Decodable & Sendable>(
        endpoint: any APIEndpoint,
        multipartFormData: @escaping @Sendable (MultipartFormData) -> Void
    ) async throws -> T {
        let data = try await session.upload(
            multipartFormData: multipartFormData,
            to: endpoint.url,
            method: endpoint.method,
            headers: endpoint.headers
        )
        .serializingData()
        .value

        try Self.checkForAPIError(in: data)
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - API Error Check

    private struct APIResponseMeta: Decodable {
        let success: Bool?
        let code: String?
        let message: String?
    }

    private static func checkForAPIError(in data: Data) throws {
        guard let meta = try? snakeCaseDecoder.decode(APIResponseMeta.self, from: data),
              meta.success == false else { return }
        throw APIError(
            code: meta.code ?? "",
            message: meta.message ?? "알 수 없는 오류가 발생했어요."
        )
    }

    // MARK: - Helpers

    private static let snakeCaseDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

#if DEBUG
private final class ConsoleNetworkLogger: EventMonitor {
    let queue = DispatchQueue(label: "com.pickflow.ConsoleNetworkLogger")

    func request(_ request: Request, didCreateURLRequest urlRequest: URLRequest) {
        let method = urlRequest.httpMethod ?? "?"
        let url = urlRequest.url?.absoluteString ?? "(no url)"
        print("🌐 [REQ] \(method) \(url)")
    }

    func request(_ request: Request, didCompleteTask task: URLSessionTask, with error: AFError?) {
        let method = task.originalRequest?.httpMethod ?? "?"
        let urlObj = task.originalRequest?.url
        let path = urlObj.map { "\($0.path)\($0.query.map { "?\($0)" } ?? "")" } ?? "(no url)"
        let status = (task.response as? HTTPURLResponse)?.statusCode ?? -1
        let icon = (200..<300).contains(status) ? "✅" : "⚠️"
        var bodyPreview = ""
        if let dr = request as? DataRequest, let data = dr.data, !data.isEmpty {
            let slice = data.prefix(1024)
            bodyPreview = " body=" + (String(data: slice, encoding: .utf8) ?? "<\(slice.count)B binary>")
        }
        if let error {
            print("❌ [ERR] \(method) \(path) status=\(status) error=\(error.localizedDescription)")
        } else {
            print("\(icon) [RES] \(status) \(method) \(path)\(bodyPreview)")
        }
    }
}
#endif
