import Foundation

final class AddressService: AddressServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol
    private let session: URLSession

    init(networkManager: NetworkManagerProtocol, session: URLSession = .shared) {
        self.networkManager = networkManager
        self.session = session
    }

    func searchAddress(query: String) async throws -> [Address] {
        var components = URLComponents(string: "https://dapi.kakao.com/v2/local/search/keyword.json")!
        components.queryItems = [URLQueryItem(name: "query", value: query)]
        let response: KakaoLocalSearchResponse = try await kakaoGET(components: components)
        return response.documents.map(Address.init(kakao:))
    }

    func reverseGeocode(latitude: Double, longitude: Double) async throws -> Address {
        var components = URLComponents(string: "https://dapi.kakao.com/v2/local/geo/coord2address.json")!
        components.queryItems = [
            URLQueryItem(name: "x", value: String(longitude)),
            URLQueryItem(name: "y", value: String(latitude)),
        ]
        let response: KakaoCoord2AddressResponse = try await kakaoGET(components: components)
        guard let document = response.documents.first else {
            throw URLError(.cannotParseResponse)
        }
        return Address(
            kakao: document,
            latitude: latitude,
            longitude: longitude
        )
    }

    private func kakaoGET<T: Decodable & Sendable>(components: URLComponents) async throws -> T {
        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let key = Bundle.main.object(forInfoDictionaryKey: "KAKAO_REST_API_KEY") as? String,
           !key.isEmpty {
            request.setValue("KakaoAK \(key)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
}

private struct KakaoLocalSearchResponse: Decodable, Sendable {
    let documents: [KakaoLocalDocument]
}

private struct KakaoLocalDocument: Decodable, Sendable {
    let id: String
    let placeName: String
    let addressName: String
    let roadAddressName: String?
    let x: String
    let y: String
}

private struct KakaoCoord2AddressResponse: Decodable, Sendable {
    let documents: [KakaoCoord2AddressDocument]
}

private struct KakaoCoord2AddressDocument: Decodable, Sendable {
    let roadAddress: KakaoCoord2RoadAddress?
    let address: KakaoCoord2Address?
}

private struct KakaoCoord2RoadAddress: Decodable, Sendable {
    let addressName: String
    let region1depthName: String?
    let region2depthName: String?
    let zoneNo: String?
}

private struct KakaoCoord2Address: Decodable, Sendable {
    let addressName: String
    let region1depthName: String?
    let region2depthName: String?
}

private extension Address {
    init(kakao document: KakaoLocalDocument) {
        let coordinate: Coordinate?
        if let lat = Double(document.y), let lon = Double(document.x) {
            coordinate = Coordinate(latitude: lat, longitude: lon)
        } else {
            coordinate = nil
        }

        let roadAddress = document.roadAddressName?.isEmpty == false ? document.roadAddressName : nil

        self.init(
            id: document.id,
            name: document.placeName,
            fullAddress: document.addressName,
            roadAddress: roadAddress,
            jibunAddress: document.addressName,
            zipCode: nil,
            city: nil,
            district: nil,
            coordinate: coordinate
        )
    }

    init(kakao document: KakaoCoord2AddressDocument, latitude: Double, longitude: Double) {
        let road = document.roadAddress
        let jibun = document.address
        let primary = road?.addressName ?? jibun?.addressName ?? ""
        self.init(
            id: "reverse-\(latitude)-\(longitude)",
            name: nil,
            fullAddress: primary,
            roadAddress: road?.addressName,
            jibunAddress: jibun?.addressName,
            zipCode: road?.zoneNo,
            city: road?.region1depthName ?? jibun?.region1depthName,
            district: road?.region2depthName ?? jibun?.region2depthName,
            coordinate: Coordinate(latitude: latitude, longitude: longitude)
        )
    }
}
