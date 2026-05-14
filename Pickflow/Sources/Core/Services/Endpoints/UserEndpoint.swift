import Alamofire
import Foundation

enum UserEndpoint: APIEndpoint {
    case deleteAccount
    case updateProfile(nickname: String?, email: String?)
    case savedSpots(page: Int?, latitude: Double?, longitude: Double?)

    var baseURL: String { APIBaseURL.current }

    var path: String {
        switch self {
        case .deleteAccount, .updateProfile: "/v1/users/me"
        case .savedSpots: "/v1/users/me/saved-spots"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .deleteAccount: .delete
        case .updateProfile: .patch
        case .savedSpots: .get
        }
    }

    var encoding: any ParameterEncoding { URLEncoding.queryString }

    var parameters: Parameters? {
        switch self {
        case .deleteAccount:
            nil
        case let .updateProfile(nickname, email):
            var p: Parameters = [:]
            if let nickname { p["nickname"] = nickname }
            if let email { p["email"] = email }
            return p.isEmpty ? nil : p
        case let .savedSpots(page, latitude, longitude):
            var p: Parameters = [:]
            if let page { p["page"] = page }
            if let latitude { p["latitude"] = latitude }
            if let longitude { p["longitude"] = longitude }
            return p.isEmpty ? nil : p
        }
    }
}
