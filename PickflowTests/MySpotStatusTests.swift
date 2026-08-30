import XCTest
@testable import Pickflow

/// 상태 값 하나가 어긋나면 스팟 목록 **전체**가 디코딩 실패로 비어버린다.
/// 서버 상태 흐름(DRAFT → PENDING → PUBLISHED / REJECTED → RE_REVIEW_PENDING)을 고정해둔다.
final class MySpotStatusTests: XCTestCase {

    func test_서버상태값이_모두디코딩된다() throws {
        let cases: [(String, MySpotStatus)] = [
            ("DRAFT", .draft),
            ("PENDING", .pending),
            ("RE_REVIEW_PENDING", .reReviewPending),
            ("PUBLISHED", .published),
            ("REJECTED", .rejected),
        ]

        for (raw, expected) in cases {
            XCTAssertEqual(try decodeStatus(raw), expected, raw)
        }
    }

    /// 서버가 새 상태를 추가해도 목록 전체가 깨지면 안 된다.
    func test_모르는상태는_unknown으로흘려보낸다() throws {
        XCTAssertEqual(try decodeStatus("ARCHIVED"), .unknown)
    }

    func test_나만보기와_알수없는상태는_뱃지를달지않는다() {
        XCTAssertNil(MySpotStatus.draft.badgeText)
        XCTAssertNil(MySpotStatus.unknown.badgeText)
    }

    /// 재검토 대기는 어드민 구분일 뿐이라 유저에게는 검수중과 같게 보인다.
    func test_재검토대기는_검수중과같은표기다() {
        XCTAssertEqual(MySpotStatus.reReviewPending.badgeText, MySpotStatus.pending.badgeText)
        XCTAssertEqual(MySpotStatus.pending.badgeText, "검수 중")
    }

    /// 실제 응답 형태 그대로 — 나만보기 스팟과 축약 테마 코드가 함께 온다.
    func test_실제응답_페이지가디코딩된다() throws {
        let json = Data("""
        {
          "spots": [
            {
              "spotId": 94,
              "name": "스팟검수 테스트",
              "theme": "NV",
              "imageUrl": "https://example.com/a.jpg",
              "latitude": 37.507681,
              "longitude": 127.099113,
              "distanceKm": 3.62,
              "createdAt": "2026-08-21T22:59:52.617102",
              "status": "DRAFT",
              "bookmarkCount": 0
            }
          ],
          "page": 0,
          "hasNext": false
        }
        """.utf8)

        let page = try JSONDecoder.pickflow.decode(MySpotListPage.self, from: json)

        XCTAssertEqual(page.spots.count, 1)
        XCTAssertEqual(page.spots.first?.status, .draft)
        XCTAssertEqual(page.spots.first?.theme, .nightView)
        XCTAssertNil(page.spots.first?.status.badgeText)
    }

    private func decodeStatus(_ raw: String) throws -> MySpotStatus {
        try JSONDecoder().decode(MySpotStatus.self, from: Data("\"\(raw)\"".utf8))
    }
}
