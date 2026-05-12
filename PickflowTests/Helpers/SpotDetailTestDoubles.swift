import CoreLocation
import Foundation
@testable import Pickflow

enum TestError: Error, LocalizedError {
    case failed

    var errorDescription: String? { "test failure" }
}

final class MockSpotService: SpotServiceProtocol, @unchecked Sendable {
    var result: Result<SpotDetail, any Error> = .success(.fixture())
    var reportError: (any Error)?
    private(set) var requests: [(id: Int64, latitude: Double?, longitude: Double?)] = []
    private(set) var reportedSpotIds: [Int64] = []
    private(set) var reportedTypes: [SpotReportType] = []

    func fetchSpotDetail(id: Int64, latitude: Double?, longitude: Double?) async throws -> SpotDetail {
        requests.append((id, latitude, longitude))
        return try result.get()
    }

    func registerSpot(draft _: SpotRegistrationDraft) async throws -> SpotId {
        SpotId(rawValue: "spot-1")
    }

    func reportSpot(id: Int64, type: SpotReportType) async throws {
        reportedSpotIds.append(id)
        reportedTypes.append(type)
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

    func requestAuthorization() {}

    func authorizationStatus() -> CLAuthorizationStatus {
        .authorizedWhenInUse
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

final class MockTokenStore: TokenStoreProtocol, @unchecked Sendable {
    var storedToken: AuthToken?

    func save(_ token: AuthToken) throws { storedToken = token }
    func load() throws -> AuthToken? { storedToken }
    func clear() throws { storedToken = nil }
}

@MainActor
final class MockShareSheetPresenter: ShareSheetPresenterProtocol {
    private(set) var presentedItems: [[String]] = []

    func present(items: [String]) {
        presentedItems.append(items)
    }
}

extension SpotDetail {
    static func fixture(
        isBookmarked: Bool = false,
        bookmarkCount: Int = 34,
        isMine: Bool = false,
        theme: SpotTheme = .sunset,
        imageURL: String? = "https://example.com/spot.jpg",
        comment: String = "걷다 보면 멀리 노을이 번져요."
    ) -> SpotDetail {
        let images: [SpotImage] = imageURL.map {
            [SpotImage(imageURL: $0, displayOrder: 0, recordedTime: "19:30")]
        } ?? []
        return SpotDetail(
            id: 1,
            name: "동작구 산책로",
            comment: comment,
            theme: theme,
            latitude: 37.501,
            longitude: 126.951,
            distance: 2.5,
            address: "서울 동작구",
            images: images,
            isBookmarked: isBookmarked,
            bookmarkCount: bookmarkCount,
            isMine: isMine,
            weather: SpotWeather(
                temperature: 22,
                precipitationProbability: 15,
                condition: .clear,
                sunsetTime: "18:40",
                congestion: .relaxed,
                parking: isMine ? nil : "무료 주차장"
            )
        )
    }
}
