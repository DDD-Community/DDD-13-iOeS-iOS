import Alamofire
import Foundation

/// 스팟 추천(좋아요) 등록/취소. (PV-40)
/// 공개된 스팟에만 허용되며, 그 외 상태의 유저 스팟은 서버가 SL003으로 거절한다.
enum SpotLikeEndpoint: APIEndpoint {
    case like(spotId: Int64)
    case unlike(spotId: Int64)

    var baseURL: String { APIBaseURL.current }

    var path: String {
        switch self {
        case let .like(spotId), let .unlike(spotId):
            "/v1/spots/\(spotId)/likes"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .like: .post
        case .unlike: .delete
        }
    }

    var parameters: Parameters? { nil }
}
