import Alamofire
import Foundation

enum ArchiveEndpoint: APIEndpoint {
    // FIXME(BE-API): BE 오픈 시 응답 스펙 확인 후 파라미터 추가
    case fetchArchive(page: Int)
    case uploadImage                // KAN-53 범위 밖

    var baseURL: String { APIBaseURL.current }
    var path: String { "/v1/users/me/archive" }

    var method: HTTPMethod {
        switch self {
        case .fetchArchive: .get
        case .uploadImage: .post
        }
    }

    var parameters: Parameters? {
        switch self {
        case let .fetchArchive(page):
            ["page": page]
        case .uploadImage:
            nil
        }
    }
}
