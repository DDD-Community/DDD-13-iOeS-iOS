import Foundation
@testable import Pickflow

enum TestError: Error, LocalizedError {
    case failed

    var errorDescription: String? { "test failure" }
}

final class MockSpotService: SpotServiceProtocol, @unchecked Sendable {
    var result: Result<SpotDetail, any Error> = .success(.fixture())
    private(set) var requests: [(id: Int64, latitude: Double?, longitude: Double?)] = []

    func fetchSpotDetail(id: Int64, latitude: Double?, longitude: Double?) async throws -> SpotDetail {
        requests.append((id, latitude, longitude))
        return try result.get()
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

extension SpotDetail {
    static func fixture(isBookmarked: Bool = false) -> SpotDetail {
        SpotDetail(
            id: 1,
            name: "동작구 산책로",
            comment: "걷다 보면 멀리 노을이 번져요.",
            theme: .sunset,
            latitude: 37.501,
            longitude: 126.951,
            distance: 2.5,
            address: "서울 동작구",
            images: [
                SpotImage(imageURL: "https://example.com/spot.jpg", displayOrder: 0, recordedTime: "19:30"),
            ],
            isBookmarked: isBookmarked,
            weather: SpotWeather(
                temperature: 22,
                precipitationProbability: 10,
                condition: .clear,
                sunsetTime: "19:44",
                congestion: .relaxed
            )
        )
    }
}
