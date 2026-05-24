import CoreLocation
import Foundation
@testable import Pickflow

enum TestError: Error, LocalizedError {
    case failed

    var errorDescription: String? { "test failure" }
}

final class MockSpotService: SpotServiceProtocol, @unchecked Sendable {
    var result: Result<SpotDetail, any Error> = .success(.fixture())
    var registerSpotResult: Result<SpotId, any Error> = .success(SpotId(rawValue: "mock-spot-id"))
    var reportError: (any Error)?
    private(set) var requests: [(id: Int64, latitude: Double?, longitude: Double?)] = []
    private(set) var registerDrafts: [SpotRegistrationDraft] = []
    private(set) var reportedSpotIds: [Int64] = []
    private(set) var reportedTypes: [SpotReportType] = []
    private(set) var reportedContents: [String] = []

    func fetchSpotDetail(id: Int64, latitude: Double?, longitude: Double?) async throws -> SpotDetail {
        requests.append((id, latitude, longitude))
        return try result.get()
    }

    func registerSpot(draft: SpotRegistrationDraft) async throws -> SpotId {
        registerDrafts.append(draft)
        return try registerSpotResult.get()
    }

    func reportSpot(id: Int64, type: SpotReportType, content: String) async throws {
        reportedSpotIds.append(id)
        reportedTypes.append(type)
        reportedContents.append(content)
        if let reportError { throw reportError }
    }
}

final class MockBookmarkService: BookmarkServiceProtocol, @unchecked Sendable {
    var addError: (any Error)?
    var deleteError: (any Error)?
    private(set) var addedSpotIds: [Int64] = []
    private(set) var deletedSpotIds: [Int64] = []

    func addBookmark(spotId: Int64) async throws {
        addedSpotIds.append(spotId)
        if let addError { throw addError }
    }

    func deleteBookmark(spotId: Int64) async throws {
        deletedSpotIds.append(spotId)
        if let deleteError { throw deleteError }
    }
}

final class MockShareIntentService: ShareIntentServiceProtocol, @unchecked Sendable {
    var error: (any Error)?
    private(set) var deviceIds: [String] = []

    func recordIntent(deviceId: String) async throws {
        deviceIds.append(deviceId)
        if let error { throw error }
    }
}

final class MockLocationService: LocationServiceProtocol, @unchecked Sendable {
    var result: Result<Coordinate, any Error> = .success(Coordinate(latitude: 37.1, longitude: 127.1))
    var stubbedAuthorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse

    func requestAuthorization() {}

    func authorizationStatus() -> CLAuthorizationStatus {
        stubbedAuthorizationStatus
    }

    func currentLocation() async throws -> Coordinate {
        try result.get()
    }

    func startUpdatingLocation() -> AsyncStream<Coordinate> {
        AsyncStream { continuation in
            if case let .success(coordinate) = result {
                continuation.yield(coordinate)
            }
            continuation.finish()
        }
    }
}

@MainActor
final class MockExternalAppLauncher: ExternalAppLauncherProtocol {
    private(set) var routes: [(latitude: Double, longitude: Double, name: String)] = []
    var isNaverMapInstalled = true
    private(set) var openedURLs: [URL] = []

    func openNaverMapsRoute(latitude: Double, longitude: Double, name: String) {
        routes.append((latitude, longitude, name))
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        if isNaverMapInstalled {
            openedURLs.append(URL(string: "nmap://route/public?dlat=\(latitude)&dlng=\(longitude)&dname=\(encodedName)&appname=test")!)
        } else {
            openedURLs.append(URL(string: "https://apps.apple.com/kr/app/id311867728")!)
        }
    }
}

@MainActor
final class MockShareSheetPresenter: ShareSheetPresenterProtocol {
    private(set) var presentedItems: [[String]] = []

    func present(items: [String]) {
        presentedItems.append(items)
    }
}

final class MockAnalyticsLogger: AnalyticsLoggerProtocol, @unchecked Sendable {
    private(set) var loggedEvents: [AnalyticsEvent] = []

    func log(_ event: AnalyticsEvent) {
        loggedEvents.append(event)
    }
}

extension SpotDetail {
    static func fixture(
        isBookmarked: Bool = false,
        bookmarkCount: Int = 34,
        isMySpot: Bool = false,
        theme: SpotTheme = .sunset,
        imageURL: String? = "https://example.com/spot.jpg",
        comment: String = "걷다 보면 멀리 노을이 번져요."
    ) -> SpotDetail {
        SpotDetail(
            id: 1,
            name: "동작구 산책로",
            comment: comment,
            theme: theme,
            latitude: 37.501,
            longitude: 126.951,
            address: "서울 동작구",
            imageUrl: imageURL,
            recordedTime: imageURL != nil ? "19:30" : nil,
            isBookmarked: isBookmarked,
            bookmarkCount: bookmarkCount,
            isMySpot: isMySpot,
            weather: SpotWeather(
                precipitationProbability: 15,
                condition: .clear,
                sunsetTime: "18:40",
                congestion: .relaxed,
                parking: isMySpot ? nil : "무료 주차장"
            )
        )
    }
}
