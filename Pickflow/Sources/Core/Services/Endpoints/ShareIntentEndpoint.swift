import Alamofire
import Foundation

struct ShareIntentEndpoint: APIEndpoint {
    let deviceId: String

    var baseURL: String { APIBaseURL.current }
    var path: String { "/share-intents" }
    var method: HTTPMethod { .post }
    var parameters: Parameters? { ["device_id": deviceId] }
}
