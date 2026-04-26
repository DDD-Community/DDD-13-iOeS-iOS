#if DEBUG
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
            // TODO: KAN-51 API/asset 연결 후 실제 images[0] URL로 대체
            SpotImage(imageURL: "", displayOrder: 0, recordedTime: "19:30"),
        ],
        isBookmarked: false,
        weather: SpotWeather(
            temperature: 22,
            precipitationProbability: 10,
            condition: .clear,
            sunsetTime: "19:44",
            congestion: .relaxed
        )
    )
}

final class DebugSpotService: SpotServiceProtocol, Sendable {
    func fetchSpotDetail(id: Int64, latitude: Double?, longitude: Double?) async throws -> SpotDetail {
        // TODO: KAN-51 API 사용 가능해지면 ContentView debug 진입점에서 실제 SpotService로 복구
        SpotDetailDebugFixture.spot
    }
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
}
#endif
