#if DEBUG
import CoreLocation
import Foundation

enum SpotDetailDebugFixture {
    static let spot = SpotDetail(
        id: 1,
        name: "동작구 산책로",
        comment: "걷다 보면 멀리 노을이 번져요.\n하늘 비율을 크게 잡아보세요.",
        theme: .sunset,
        latitude: 37.501,
        longitude: 126.951,
        distance: 3.5,
        address: "서울 동작구",
        images: [
            SpotImage(imageURL: "", displayOrder: 0, recordedTime: "19:30"),
        ],
        isBookmarked: false,
        bookmarkCount: 34,
        isMine: false,
        weather: SpotWeather(
            temperature: 22,
            precipitationProbability: 10,
            condition: .clear,
            sunsetTime: "19:44",
            congestion: .relaxed,
            parking: "무료 주차장"
        )
    )

    static let mySpot = SpotDetail(
        id: 2,
        name: "동작구 산책로",
        comment: "걷다 보면 멀리 노을이 번져요.\n하늘 비율을 크게 잡아보세요.",
        theme: .sunset,
        latitude: 37.501,
        longitude: 126.951,
        distance: 3.5,
        address: "서울 동작구",
        images: [
            SpotImage(imageURL: "", displayOrder: 0, recordedTime: "19:30"),
        ],
        isBookmarked: true,
        bookmarkCount: 0,
        isMine: true,
        weather: SpotWeather(
            temperature: 22,
            precipitationProbability: 10,
            condition: .clear,
            sunsetTime: "19:44",
            congestion: .relaxed,
            parking: nil
        )
    )
}

final class DebugSpotService: SpotServiceProtocol, Sendable {
    func fetchSpotDetail(id: Int64, latitude: Double?, longitude: Double?) async throws -> SpotDetail {
        SpotDetailDebugFixture.spot
    }

    func registerSpot(draft: SpotRegistrationDraft) async throws -> SpotId {
        SpotId(rawValue: "debug-spot-id")
    }

    func reportSpot(id: Int64, type: SpotReportType, content: String) async throws {}
}

final class DebugMySpotService: SpotServiceProtocol, Sendable {
    func fetchSpotDetail(id: Int64, latitude: Double?, longitude: Double?) async throws -> SpotDetail {
        SpotDetailDebugFixture.mySpot
    }

    func registerSpot(draft: SpotRegistrationDraft) async throws -> SpotId {
        SpotId(rawValue: "debug-spot-id")
    }

    func reportSpot(id: Int64, type: SpotReportType, content: String) async throws {}
}

final class DebugBookmarkService: BookmarkServiceProtocol, Sendable {
    func addBookmark(spotId: Int64) async throws {
        // TODO: KAN-51 API 사용 가능해지면 실제 POST /bookmarks 호출로 복구
    }

    func deleteBookmark(spotId: Int64) async throws {
        // TODO: KAN-51 API 사용 가능해지면 실제 DELETE /bookmarks/:spotId 호출로 복구
    }
}

final class DebugShareIntentService: ShareIntentServiceProtocol, Sendable {
    func recordIntent(deviceId: String) async throws {
        // TODO: KAN-51 API 사용 가능해지면 실제 POST /share-intents 호출로 복구
    }
}

final class DebugLocationService: LocationServiceProtocol, Sendable {
    func requestAuthorization() {}

    func authorizationStatus() -> CLAuthorizationStatus { .authorizedWhenInUse }

    func currentLocation() async throws -> Coordinate {
        Coordinate(latitude: 37.501, longitude: 126.951)
    }

    func startUpdatingLocation() -> AsyncStream<Coordinate> {
        AsyncStream { continuation in
            continuation.yield(Coordinate(latitude: 37.501, longitude: 126.951))
            continuation.finish()
        }
    }
}

@MainActor
enum SpotDetailDebugFactory {
    static func makeViewModel(spotId: Int64) -> SpotDetailViewModel {
        SpotDetailViewModel(
            spotId: spotId,
            spotService: DebugSpotService(),
            bookmarkService: DebugBookmarkService(),
            shareIntentService: DebugShareIntentService(),
            locationService: DebugLocationService(),
            externalAppLauncher: getExternalAppLauncher(),
            shareSheetPresenter: getShareSheetPresenter(),
            deviceIdProvider: { "debug-device" }
        )
    }

    static func makeMyViewModel(spotId: Int64) -> SpotDetailViewModel {
        SpotDetailViewModel(
            spotId: spotId,
            spotService: DebugMySpotService(),
            bookmarkService: DebugBookmarkService(),
            shareIntentService: DebugShareIntentService(),
            locationService: DebugLocationService(),
            externalAppLauncher: getExternalAppLauncher(),
            shareSheetPresenter: getShareSheetPresenter(),
            deviceIdProvider: { "debug-device" }
        )
    }
}
#endif
