import Alamofire
import XCTest
@testable import Pickflow

/// PV-40 엔드포인트 경로/메서드 계약.
final class SpotPublicationEndpointTests: XCTestCase {
    private let spotId: Int64 = 42

    func test_나만의스팟_수정은_PUT_my_spots() {
        let endpoint = MySpotEndpoint.update(spotId: spotId)
        XCTAssertEqual(endpoint.path, "/v1/users/me/my-spots/42")
        XCTAssertEqual(endpoint.method, .put)
    }

    func test_나만의스팟_삭제는_DELETE_my_spots() {
        let endpoint = MySpotEndpoint.delete(spotId: spotId)
        XCTAssertEqual(endpoint.path, "/v1/users/me/my-spots/42")
        XCTAssertEqual(endpoint.method, .delete)
    }

    func test_오픈신청은_POST_open_requests() {
        let endpoint = MySpotEndpoint.requestOpen(spotId: spotId)
        XCTAssertEqual(endpoint.path, "/v1/users/me/my-spots/42/open-requests")
        XCTAssertEqual(endpoint.method, .post)
    }

    func test_공개해제는_DELETE_publications() {
        let endpoint = MySpotEndpoint.cancelPublication(spotId: spotId)
        XCTAssertEqual(endpoint.path, "/v1/users/me/my-spots/42/publications")
        XCTAssertEqual(endpoint.method, .delete)
    }

    func test_추천_등록과_취소는_같은_경로에_메서드만_다르다() {
        let like = SpotLikeEndpoint.like(spotId: spotId)
        let unlike = SpotLikeEndpoint.unlike(spotId: spotId)
        XCTAssertEqual(like.path, "/v1/spots/42/likes")
        XCTAssertEqual(unlike.path, "/v1/spots/42/likes")
        XCTAssertEqual(like.method, .post)
        XCTAssertEqual(unlike.method, .delete)
    }
}
