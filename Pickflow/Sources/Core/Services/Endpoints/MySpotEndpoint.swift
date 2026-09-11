import Alamofire
import Foundation

/// 내가 등록한 스팟의 수정/삭제/오픈신청/공개해제. (PV-40)
enum MySpotEndpoint: APIEndpoint {
    /// 나만보기(DRAFT)·반려(REJECTED) 상태의 스팟 수정. multipart.
    case update(spotId: Int64)
    /// 논리 삭제. 검수중이면 서버가 409(SP011)로 거절한다.
    case delete(spotId: Int64)
    /// 오픈 신청(검수 요청). DRAFT → PENDING, REJECTED → RE_REVIEW_PENDING.
    case requestOpen(spotId: Int64)
    /// 공개 해제. 검수중이면 신청 철회, 공개중이면 비공개 전환(DRAFT)으로 처리된다.
    case cancelPublication(spotId: Int64)
    /// 노출 켜기. status(검수 flow)와 독립적인 별도 플래그라 재검수가 없다.
    case releaseSpot(spotId: Int64)
    /// 노출 끄기. 마찬가지로 status 는 PUBLISHED 로 유지된다.
    case unreleaseSpot(spotId: Int64)

    var baseURL: String { APIBaseURL.current }

    var path: String {
        switch self {
        case let .update(spotId), let .delete(spotId):
            "/v1/users/me/my-spots/\(spotId)"
        case let .requestOpen(spotId):
            "/v1/users/me/my-spots/\(spotId)/open-requests"
        case let .cancelPublication(spotId):
            "/v1/users/me/my-spots/\(spotId)/publications"
        case let .releaseSpot(spotId), let .unreleaseSpot(spotId):
            "/v1/users/me/my-spots/\(spotId)/releases"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .update: .put
        case .delete, .cancelPublication, .unreleaseSpot: .delete
        case .requestOpen, .releaseSpot: .post
        }
    }

    var parameters: Parameters? { nil }
}
