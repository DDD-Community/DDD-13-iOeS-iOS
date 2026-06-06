import Alamofire
import Foundation

enum AppVersionEndpoint: APIEndpoint {
    /// iOS 앱 버전 정책 조회.
    case iOS

    var baseURL: String { APIBaseURL.current }

    var path: String {
        switch self {
        case .iOS: "/v1/app/config/ios"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .iOS: .get
        }
    }
}
