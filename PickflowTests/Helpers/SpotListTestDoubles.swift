import CoreLocation
import Foundation
@testable import Pickflow

final class MockSpotListService: SpotListServiceProtocol, @unchecked Sendable {
    struct Request: Equatable {
        let page: Int
        let theme: SpotTheme?
        let latitude: Double?
        let longitude: Double?
    }

    /// 페이지별 응답 스텁. 기본은 빈 페이지.
    var responder: @Sendable (Request) -> Result<SpotListPage, any Error> = { _ in
        .success(SpotListPage(spots: [], page: 0, hasNext: false))
    }

    private(set) var requests: [Request] = []

    func fetchSpots(
        page: Int,
        theme: SpotTheme?,
        latitude: Double?,
        longitude: Double?
    ) async throws -> SpotListPage {
        let request = Request(page: page, theme: theme, latitude: latitude, longitude: longitude)
        requests.append(request)
        return try responder(request).get()
    }
}

extension SpotListItem {
    static func fixture(
        spotId: Int64 = 1,
        name: String = "한강 노을 스팟",
        theme: SpotTheme = .sunset,
        thumbnailUrl: String? = "https://example.com/spot.jpg",
        distanceKm: Double? = 1.2
    ) -> SpotListItem {
        SpotListItem(
            spotId: spotId,
            name: name,
            theme: theme,
            thumbnailUrl: thumbnailUrl,
            distanceKm: distanceKm
        )
    }
}
