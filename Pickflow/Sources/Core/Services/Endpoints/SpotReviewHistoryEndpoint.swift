import Alamofire
import Foundation

/// 검수완료 알림 히스토리 조회/확인. (PV-40)
enum SpotReviewHistoryEndpoint: APIEndpoint {
    case fetchUnchecked
    case checkStatus(historyId: Int64)

    var baseURL: String { APIBaseURL.current }

    var path: String {
        switch self {
        case .fetchUnchecked:
            "/v1/users/me/spot-open-review-histories"
        case let .checkStatus(historyId):
            "/v1/users/me/spot-open-review-histories/\(historyId)/check-status"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchUnchecked: .get
        case .checkStatus: .patch
        }
    }

    var parameters: Parameters? { nil }
}
