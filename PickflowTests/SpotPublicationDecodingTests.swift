import XCTest
@testable import Pickflow

/// PV-40 유저 스팟 공개 시스템 — 서버 응답 디코딩 계약.
final class SpotPublicationDecodingTests: XCTestCase {
    private let decoder = JSONDecoder.pickflow

    // MARK: - SpotTheme

    func test_SpotTheme_긴코드_4종을_모두_디코딩한다() throws {
        let pairs: [(String, SpotTheme)] = [
            ("SUNLIGHT", .sunlight),
            ("YUNSEUL", .reflection),
            ("SUNSET", .sunset),
            ("NIGHT_VIEW", .nightView),
        ]
        for (code, expected) in pairs {
            let decoded = try decoder.decode(SpotTheme.self, from: Data("\"\(code)\"".utf8))
            XCTAssertEqual(decoded, expected, "\(code) 디코딩 실패")
        }
    }

    func test_SpotTheme_리스트용_짧은코드_4종을_모두_디코딩한다() throws {
        let pairs: [(String, SpotTheme)] = [
            ("SL", .sunlight),
            ("YS", .reflection),
            ("SS", .sunset),
            ("NV", .nightView),
        ]
        for (code, expected) in pairs {
            let decoded = try decoder.decode(SpotTheme.self, from: Data("\"\(code)\"".utf8))
            XCTAssertEqual(decoded, expected, "\(code) 디코딩 실패")
        }
    }

    func test_SpotTheme_apiCode_는_왕복한다() throws {
        for theme in SpotTheme.allCases {
            XCTAssertEqual(SpotTheme(apiCode: theme.apiCode), theme)
        }
    }

    func test_SpotTheme_카테고리_노출순서는_햇살_윤슬_노을_야경() {
        XCTAssertEqual(SpotTheme.allCases, [.sunlight, .reflection, .sunset, .nightView])
    }

    // MARK: - MySpotStatus

    func test_MySpotStatus_신규상태_DRAFT_와_RE_REVIEW_PENDING_을_디코딩한다() throws {
        let draft = try decoder.decode(MySpotStatus.self, from: Data("\"DRAFT\"".utf8))
        let reReview = try decoder.decode(MySpotStatus.self, from: Data("\"RE_REVIEW_PENDING\"".utf8))
        XCTAssertEqual(draft, .draft)
        XCTAssertEqual(reReview, .reReviewPending)
    }

    func test_MySpotStatus_모르는_상태값은_unknown_으로_떨어진다() throws {
        let decoded = try decoder.decode(MySpotStatus.self, from: Data("\"SOMETHING_NEW\"".utf8))
        XCTAssertEqual(decoded, .unknown)
    }

    func test_MySpotStatus_검수중_판정은_PENDING_과_RE_REVIEW_PENDING_뿐() {
        XCTAssertTrue(MySpotStatus.pending.isUnderReview)
        XCTAssertTrue(MySpotStatus.reReviewPending.isUnderReview)
        XCTAssertFalse(MySpotStatus.draft.isUnderReview)
        XCTAssertFalse(MySpotStatus.published.isUnderReview)
        XCTAssertFalse(MySpotStatus.rejected.isUnderReview)
    }

    func test_MySpotListItem_모르는_상태여도_항목_전체가_깨지지_않는다() throws {
        let json = """
        {
          "spotId": 7, "name": "석촌호수 산책길", "theme": "NIGHT_VIEW",
          "imageUrl": null, "latitude": 37.5, "longitude": 127.1,
          "distanceKm": 1.2, "createdAt": "2026-04-11", "status": "FUTURE_STATE",
          "bookmarkCount": 3
        }
        """
        let item = try decoder.decode(MySpotListItem.self, from: Data(json.utf8))
        XCTAssertEqual(item.status, .unknown)
        XCTAssertEqual(item.theme, .nightView)
    }

    // MARK: - SpotDetail

    func test_SpotDetail_PV40_신규필드를_디코딩한다() throws {
        let json = """
        {
          "spotId": 1, "name": "석촌호수 산책길", "comment": "노을빛에 반사된 윤슬이 가장 반짝여요.",
          "theme": "YUNSEUL", "latitude": 37.5, "longitude": 127.1,
          "address": "서울특별시 송파구", "imageUrl": null,
          "bookmarkCount": 3, "isBookmarked": false, "isMySpot": true,
          "status": "REJECTED", "isCurated": false,
          "likeCount": 34, "isLiked": true, "isLikeable": false,
          "rejection": {
            "reason": "FILTER_MISMATCH",
            "reasonLabel": "카테고리 불일치",
            "guideMessage": "선택하신 카테고리와 사진이 일치하지 않습니다.",
            "detail": null,
            "rejectedAt": "2026-07-21T10:00:00Z"
          }
        }
        """
        let detail = try decoder.decode(SpotDetail.self, from: Data(json.utf8))
        XCTAssertEqual(detail.status, .rejected)
        XCTAssertEqual(detail.isCurated, false)
        XCTAssertEqual(detail.likeCount, 34)
        XCTAssertEqual(detail.isLiked, true)
        XCTAssertEqual(detail.isLikeable, false)
        XCTAssertEqual(detail.rejection?.reason, "FILTER_MISMATCH")
        XCTAssertEqual(detail.rejection?.guideMessage, "선택하신 카테고리와 사진이 일치하지 않습니다.")
    }

    func test_SpotDetail_PV40_필드가_없어도_디코딩된다() throws {
        let json = """
        {
          "spotId": 1, "name": "석촌호수 산책길", "comment": "코멘트",
          "theme": "SUNSET", "latitude": 37.5, "longitude": 127.1,
          "address": "서울특별시 송파구", "imageUrl": null,
          "bookmarkCount": 0, "isBookmarked": false, "isMySpot": false
        }
        """
        let detail = try decoder.decode(SpotDetail.self, from: Data(json.utf8))
        XCTAssertNil(detail.status)
        XCTAssertNil(detail.likeCount)
        XCTAssertNil(detail.rejection)
    }

    // MARK: - 저장된 스팟 / 미리보기 / 리스트

    func test_SavedSpotItem_비공개_전환된_항목은_isPrivate_이고_imageUrl_이_마스킹된다() throws {
        let json = """
        {
          "spotId": 9, "name": "잠원 노을 스팟", "theme": "SUNSET",
          "imageUrl": null, "latitude": 37.5, "longitude": 127.0,
          "distanceKm": 2.5, "bookmarkCount": 1,
          "savedAt": "2026-08-01T00:00:00Z", "deleted": false, "isPrivate": true
        }
        """
        let item = try decoder.decode(SavedSpotItem.self, from: Data(json.utf8))
        XCTAssertEqual(item.isPrivate, true)
        XCTAssertFalse(item.deleted)
        XCTAssertNil(item.imageUrl)
    }

    func test_SpotPreviewResponse_PV40_신규필드를_디코딩한다() throws {
        let json = """
        {
          "spotId": 2, "name": "잠원 한강공원", "isMySpot": false, "theme": "SUNLIGHT",
          "bookmarkCount": 5, "distanceKm": 2.5, "imageUrl": null,
          "addressSimple": "서울 서초구", "addressRoad": null, "addressJibun": null,
          "isBookmarked": false,
          "likeCount": 12, "isLiked": false, "isLikeable": true, "isCurated": true
        }
        """
        let preview = try decoder.decode(SpotPreviewResponse.self, from: Data(json.utf8))
        XCTAssertEqual(preview.theme, .sunlight)
        XCTAssertEqual(preview.likeCount, 12)
        XCTAssertEqual(preview.isLikeable, true)
        XCTAssertEqual(preview.isCurated, true)
    }

    func test_SpotListPage_는_추천수를_함께_디코딩한다() throws {
        let json = """
        {
          "spots": [
            {"spotId": 1, "name": "노들섬", "theme": "NV", "thumbnailUrl": null,
             "distanceKm": 1.0, "bookmarkCount": 2, "isBookmarked": false,
             "likeCount": 7, "isLiked": true}
          ],
          "page": 0, "hasNext": true
        }
        """
        let page = try decoder.decode(SpotListPage.self, from: Data(json.utf8))
        XCTAssertEqual(page.spots.first?.theme, .nightView)
        XCTAssertEqual(page.spots.first?.likeCount, 7)
        XCTAssertEqual(page.spots.first?.isLiked, true)
    }

    // MARK: - 공개 상태 전이 응답

    func test_CancelPublicationResponse_previousStatus_로_철회와_비공개전환을_구분한다() throws {
        let withdrawn = """
        {"spotId": 1, "previousStatus": "PENDING", "status": "DRAFT"}
        """
        let unpublished = """
        {"spotId": 1, "previousStatus": "PUBLISHED", "status": "DRAFT"}
        """
        let a = try decoder.decode(CancelPublicationResponse.self, from: Data(withdrawn.utf8))
        let b = try decoder.decode(CancelPublicationResponse.self, from: Data(unpublished.utf8))
        XCTAssertTrue(a.wasWithdrawnFromReview)
        XCTAssertFalse(b.wasWithdrawnFromReview)
        XCTAssertEqual(a.status, .draft)
        XCTAssertEqual(b.status, .draft)
    }

    func test_OpenMySpotResponse_는_재신청시_RE_REVIEW_PENDING_을_준다() throws {
        let json = #"{"spotId": 1, "status": "RE_REVIEW_PENDING"}"#
        let response = try decoder.decode(OpenMySpotResponse.self, from: Data(json.utf8))
        XCTAssertEqual(response.status, .reReviewPending)
    }

    func test_SpotLikeResponse_는_서버_최종값을_준다() throws {
        let json = #"{"likeCount": 12, "isLiked": true}"#
        let response = try decoder.decode(SpotLikeResponse.self, from: Data(json.utf8))
        XCTAssertEqual(response.likeCount, 12)
        XCTAssertTrue(response.isLiked)
    }

    // MARK: - 에러 코드

    func test_APIError_는_PV40_도메인코드로_변환된다() {
        let error: Error = APIError(code: "SP011", message: "검수 중인 스팟은 삭제할 수 없습니다.", statusCode: 409)
        XCTAssertEqual(error.spotPublicationErrorCode, .notDeletable)
    }

    func test_모르는_코드는_도메인코드로_변환되지_않는다() {
        let error: Error = APIError(code: "ZZ999", message: "?", statusCode: 500)
        XCTAssertNil(error.spotPublicationErrorCode)
    }
}
