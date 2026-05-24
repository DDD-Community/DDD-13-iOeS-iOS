import Alamofire
import Foundation

enum AuthEndpoint: APIEndpoint {
    case kakaoSignIn(accessToken: String)
    case appleSignIn(identityToken: String, user: AppleUserInfo?)
    case refresh(refreshToken: String)
    case logout(refreshToken: String)

    var baseURL: String { AppConfig.baseURL }

    var path: String {
        switch self {
        case .kakaoSignIn: "/v1/auth/kakao"
        case .appleSignIn: "/v1/auth/apple"
        case .refresh: "/v1/auth/refresh"
        case .logout: "/v1/auth/logout"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .kakaoSignIn, .appleSignIn, .refresh, .logout: .post
        }
    }

    var parameters: Parameters? {
        switch self {
        case let .kakaoSignIn(accessToken):
            return ["accessToken": accessToken]
        case let .appleSignIn(identityToken, user):
            var params: [String: any Sendable] = ["identityToken": identityToken]
            if let user {
                var userDict: [String: any Sendable] = [:]
                var nameDict: [String: any Sendable] = [:]
                if let firstName = user.firstName { nameDict["firstName"] = firstName }
                if let lastName = user.lastName { nameDict["lastName"] = lastName }
                if !nameDict.isEmpty { userDict["name"] = nameDict }
                if let email = user.email { userDict["email"] = email }
                if !userDict.isEmpty { params["user"] = userDict }
            }
            return params as Parameters
        case let .refresh(refreshToken):
            return ["refreshToken": refreshToken]
        case let .logout(refreshToken):
            return ["refreshToken": refreshToken]
        }
    }
}
