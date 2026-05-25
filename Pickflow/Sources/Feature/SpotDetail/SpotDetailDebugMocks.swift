#if DEBUG
import CoreLocation
import Foundation
import UIKit

enum SpotDetailDebugFixture {
    static let spot = SpotDetail(
        spotId: 1,
        name: "동작구 산책로",
        comment: "걷다 보면 멀리 노을이 번져요.\n하늘 비율을 크게 잡아보세요.",
        theme: .sunset,
        latitude: 37.501,
        longitude: 126.951,
        address: "서울 동작구",
        imageUrl: nil,
        recordedDate: "2026-05-23",
        recordedTime: "19:30",
        weatherSky: .clear,
        precipitation: .none,
        precipitationProbability: 10,
        congestionLevel: .relaxed,
        sunsetTime: "19:44",
        astronomyDate: "2026-05-23",
        weatherUpdatedAt: "2026-05-23T19:00:00Z",
        congestionUpdatedAt: "2026-05-23T19:00:00Z",
        parkingInfo: "무료 주차장",
        bookmarkCount: 34,
        isBookmarked: false,
        isMySpot: false
    )

    static let mySpot = SpotDetail(
        spotId: 2,
        name: "동작구 산책로",
        comment: "걷다 보면 멀리 노을이 번져요.\n하늘 비율을 크게 잡아보세요.",
        theme: .sunset,
        latitude: 37.501,
        longitude: 126.951,
        address: "서울 동작구",
        imageUrl: nil,
        recordedDate: "2026-05-23",
        recordedTime: "19:30",
        weatherSky: .clear,
        precipitation: .none,
        precipitationProbability: 10,
        congestionLevel: .relaxed,
        sunsetTime: "19:44",
        astronomyDate: "2026-05-23",
        weatherUpdatedAt: "2026-05-23T19:00:00Z",
        congestionUpdatedAt: "2026-05-23T19:00:00Z",
        parkingInfo: nil,
        bookmarkCount: 0,
        isBookmarked: true,
        isMySpot: true
    )

    static let preview = SpotPreviewResponse(
        spotId: 1,
        name: "동작구 산책로",
        isMySpot: false,
        theme: .sunset,
        bookmarkCount: 34,
        isBookmarked: false,
        distanceKm: 3.5,
        imageUrl: nil,
        addressSimple: "서울 동작구",
        addressRoad: "서울특별시 동작구 흑석한강로 100",
        addressJibun: "서울특별시 동작구 흑석동 100-1"
    )

    static let myPreview = SpotPreviewResponse(
        spotId: 2,
        name: "동작구 산책로",
        isMySpot: true,
        theme: .sunset,
        bookmarkCount: 0,
        isBookmarked: false,
        distanceKm: 3.5,
        imageUrl: nil,
        addressSimple: "서울 동작구",
        addressRoad: nil,
        addressJibun: nil
    )
}

final class DebugSpotService: SpotServiceProtocol, Sendable {
    func fetchSpotDetail(id _: Int64, latitude _: Double?, longitude _: Double?) async throws -> SpotDetail {
        SpotDetailDebugFixture.spot
    }

    func fetchSpotPreview(id _: Int64, latitude _: Double?, longitude _: Double?) async throws -> SpotPreviewResponse {
        SpotDetailDebugFixture.preview
    }

    func registerSpot(draft _: SpotRegistrationDraft) async throws -> SpotId {
        SpotId(rawValue: "debug-spot-id")
    }

    func reportSpot(id _: Int64, type _: SpotReportType, content _: String) async throws {}
}

final class DebugMySpotService: SpotServiceProtocol, Sendable {
    func fetchSpotDetail(id _: Int64, latitude _: Double?, longitude _: Double?) async throws -> SpotDetail {
        SpotDetailDebugFixture.mySpot
    }

    func fetchSpotPreview(id _: Int64, latitude _: Double?, longitude _: Double?) async throws -> SpotPreviewResponse {
        SpotDetailDebugFixture.myPreview
    }

    func registerSpot(draft _: SpotRegistrationDraft) async throws -> SpotId {
        SpotId(rawValue: "debug-spot-id")
    }

    func reportSpot(id _: Int64, type _: SpotReportType, content _: String) async throws {}
}

final class DebugBookmarkService: BookmarkServiceProtocol, Sendable {
    func addBookmark(spotId _: Int64) async throws {}
    func deleteBookmark(spotId _: Int64) async throws {}
}

final class DebugShareIntentService: ShareIntentServiceProtocol, Sendable {
    func recordIntent(deviceId _: String) async throws {}
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
    /// 실제 네트워크 서비스를 사용하는 ViewModel (API integration 테스트용)
    static func makeLiveViewModel(spotId: Int64) -> SpotDetailViewModel {
        SpotDetailViewModel(
            spotId: spotId,
            spotService: getSpotService(),
            bookmarkService: getBookmarkService(),
            shareIntentService: getShareIntentService(),
            locationService: getLocationService(),
            externalAppLauncher: getExternalAppLauncher(),
            shareSheetPresenter: getShareSheetPresenter(),
            deviceIdProvider: { UIDevice.current.identifierForVendor?.uuidString ?? "unknown" }
        )
    }

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
