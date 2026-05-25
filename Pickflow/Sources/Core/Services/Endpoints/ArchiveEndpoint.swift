import Alamofire
import Foundation

enum ArchiveEndpoint: APIEndpoint {
    case fetchInfo
    case fetchSavedSpots(page: Int, latitude: Double?, longitude: Double?)
    case renameArchive(name: String)
    case uploadImage                // KAN-53 범위 밖

    var baseURL: String { APIBaseURL.current }

    var path: String {
        switch self {
        case .fetchInfo, .uploadImage: "/v1/users/me/archive"
        case .renameArchive: "/v1/users/me/archive/name"
        case .fetchSavedSpots: "/v1/users/me/saved-spots"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchInfo, .fetchSavedSpots: .get
        case .renameArchive: .patch
        case .uploadImage: .post
        }
    }

    var parameters: Parameters? {
        switch self {
        case .fetchInfo, .uploadImage:
            return nil
        case let .renameArchive(name):
            return ["archiveName": name]
        case let .fetchSavedSpots(page, latitude, longitude):
            var params: Parameters = ["page": page]
            if let lat = latitude { params["latitude"] = (lat * 1_000_000).rounded() / 1_000_000 }
            if let lon = longitude { params["longitude"] = (lon * 1_000_000).rounded() / 1_000_000 }
            return params
        }
    }
}
