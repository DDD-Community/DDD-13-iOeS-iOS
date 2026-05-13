import Alamofire
import Foundation

struct ReportEndpoint: APIEndpoint {
    let spotId: Int64
    let reportType: SpotReportType

    var baseURL: String { APIBaseURL.current }
    var path: String { "/spots/\(spotId)/reports" }
    var method: HTTPMethod { .post }
    var parameters: Parameters? { ["report_type": reportType.rawValue] }
}
