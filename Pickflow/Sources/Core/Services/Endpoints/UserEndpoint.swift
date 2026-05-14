import Alamofire
import Foundation

enum UserEndpoint: APIEndpoint {
    case me
    case deleteAccount(reason: String, otherFeedback: String?)
    case updateProfile(nickname: String?, profileImageURL: URL?)
    case savedSpots(page: Int?, latitude: Double?, longitude: Double?)

    var baseURL: String { APIBaseURL.current }

    var path: String {
        switch self {
        case .me, .deleteAccount, .updateProfile: "/v1/users/me"
        case .savedSpots: "/v1/users/me/saved-spots"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .me: .get
        case .deleteAccount: .delete
        case .updateProfile: .patch
        case .savedSpots: .get
        }
    }

    var encoding: any ParameterEncoding {
        switch self {
        case .me, .savedSpots: return URLEncoding.queryString
        case .deleteAccount, .updateProfile: return JSONEncoding.default
        }
    }

    var parameters: Parameters? {
        switch self {
        case .me:
            return nil
        case let .deleteAccount(reason, otherFeedback):
            var p: Parameters = ["reason": reason]
            if let otherFeedback { p["otherFeedback"] = otherFeedback }
            return p
        case let .updateProfile(nickname, profileImageURL):
            var p: Parameters = [:]
            if let nickname { p["nickname"] = nickname }
            if let profileImageURL { p["profileImageUrl"] = profileImageURL.absoluteString }
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
