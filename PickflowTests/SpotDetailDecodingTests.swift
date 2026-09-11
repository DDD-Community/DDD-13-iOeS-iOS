import XCTest
@testable import Pickflow

/// 스펙상 `SpotDetailResponse` 는 required 필드가 하나도 없다.
/// 표시용 값 하나가 null 이라고 화면 전체가 "불러오지 못했어요" 로 떨어지면 안 된다.
final class SpotDetailDecodingTests: XCTestCase {

    /// 실제 dev 응답 그대로. comment / congestionLevel / addressRoad 가 null 인 케이스.
    func test_코멘트가null인_실제응답이_디코딩된다() throws {
        let spot = try JSONDecoder.pickflow.decode(SpotDetail.self, from: Self.realResponse)

        XCTAssertEqual(spot.spotId, 94)
        XCTAssertEqual(spot.name, "스팟검수 테스트")
        XCTAssertNil(spot.comment)
        XCTAssertEqual(spot.theme, .nightView)
        XCTAssertEqual(spot.address, "서울 송파구")
        XCTAssertNil(spot.addressRoad)
        XCTAssertEqual(spot.addressJibun, "서울 송파구 잠실동 47")
        XCTAssertNil(spot.congestionLevel)
        XCTAssertEqual(spot.precipitation, .rain)
        XCTAssertEqual(spot.weatherSky, .overcast)
    }

    /// 주소까지 없는 최소 응답. 서버가 채우지 못한 값들이 한꺼번에 빠져도 버텨야 한다.
    func test_주소와_코멘트가_모두없어도_디코딩된다() throws {
        let json = Data("""
        {
          "spotId": 1,
          "name": "최소 응답",
          "comment": null,
          "theme": "SUNSET",
          "latitude": 37.5,
          "longitude": 127.0,
          "address": null,
          "bookmarkCount": 0,
          "isBookmarked": false,
          "isMySpot": false
        }
        """.utf8)

        let spot = try JSONDecoder.pickflow.decode(SpotDetail.self, from: json)

        XCTAssertNil(spot.comment)
        XCTAssertNil(spot.address)
        XCTAssertNil(spot.addressRoad)
        XCTAssertNil(spot.addressJibun)
        XCTAssertNil(spot.imageUrl)
    }

    private static let realResponse = Data("""
    {
      "spotId": 94,
      "name": "스팟검수 테스트",
      "comment": null,
      "theme": "NIGHT_VIEW",
      "latitude": 37.507681,
      "longitude": 127.099113,
      "address": "서울 송파구",
      "addressRoad": null,
      "addressJibun": "서울 송파구 잠실동 47",
      "imageUrl": "https://example.com/a.jpg",
      "recordedDate": "2026-08-21",
      "recordedTime": "22:59",
      "weatherSky": "OVERCAST",
      "precipitation": "RAIN",
      "precipitationProbability": 60,
      "congestionLevel": null,
      "sunsetTime": "19:17",
      "astronomyDate": "2026-08-21",
      "weatherUpdatedAt": "2026-08-21T21:00:00",
      "congestionUpdatedAt": null,
      "parkingInfo": "-",
      "bookmarkCount": 0,
      "isBookmarked": false,
      "isMySpot": true,
      "status": "DRAFT",
      "isCurated": false,
      "likeCount": 0,
      "isLiked": false,
      "isLikeable": false,
      "rejection": null
    }
    """.utf8)
}
