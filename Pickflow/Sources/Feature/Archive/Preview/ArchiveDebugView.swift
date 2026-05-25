#if DEBUG
import CoreLocation
import SwiftUI

// MARK: - 로그인 상태 (Mock 데이터 로드)

@MainActor
struct ArchiveSignedInDebugView: View {
    private let viewModel: ArchiveViewModel = {
        let state = ArchiveDebugSharedState(isSignedIn: true)
        let vm = ArchiveViewModel(
            archiveService: ArchiveDebugService(),
            bookmarkService: ArchiveDebugBookmarkService(),
            authService: ArchiveDebugAuthService(state: state),
            socialLoginService: ArchiveDebugSocialService(state: state),
            locationService: ArchiveDebugLocationService()
        )
        vm.applyLoadedState(items: ArchiveDebugService.sampleItems)
        return vm
    }()

    var body: some View {
        ContentView(initialTab: .saved, archiveViewModel: viewModel)
    }
}

// MARK: - 비로그인 상태

@MainActor
struct ArchiveSignedOutDebugView: View {
    private let viewModel: ArchiveViewModel = {
        let state = ArchiveDebugSharedState(isSignedIn: false)
        let vm = ArchiveViewModel(
            archiveService: ArchiveDebugService(),
            bookmarkService: ArchiveDebugBookmarkService(),
            authService: ArchiveDebugAuthService(state: state),
            socialLoginService: ArchiveDebugSocialService(state: state),
            locationService: ArchiveDebugLocationService()
        )
        vm.applySignedOutState()
        return vm
    }()

    var body: some View {
        ContentView(initialTab: .saved, archiveViewModel: viewModel)
    }
}

// MARK: - 빈 상태

@MainActor
struct ArchiveEmptyDebugView: View {
    private let viewModel: ArchiveViewModel = {
        let state = ArchiveDebugSharedState(isSignedIn: true)
        let vm = ArchiveViewModel(
            archiveService: ArchiveDebugService(),
            bookmarkService: ArchiveDebugBookmarkService(),
            authService: ArchiveDebugAuthService(state: state),
            socialLoginService: ArchiveDebugSocialService(state: state),
            locationService: ArchiveDebugLocationService()
        )
        vm.applyEmptyState()
        return vm
    }()

    var body: some View {
        ContentView(initialTab: .saved, archiveViewModel: viewModel)
    }
}

// MARK: - Mock Services

final class ArchiveDebugService: ArchiveServiceProtocol, Sendable {
    static let sampleItems: [SpotListItem] = [
        SpotListItem(spotId: 1, name: "한강 노을길",      theme: .sunset,     thumbnailUrl: nil, distanceKm: 0.4),
        SpotListItem(spotId: 2, name: "잠실 윤슬",        theme: .reflection, thumbnailUrl: nil, distanceKm: 1.2),
        SpotListItem(spotId: 3, name: "응봉산 전망대",    theme: .sunset,     thumbnailUrl: nil, distanceKm: 2.0),
        SpotListItem(spotId: 4, name: "반포 무지개 분수", theme: .reflection, thumbnailUrl: nil, distanceKm: 2.8),
        SpotListItem(spotId: 5, name: "선유도 일몰 포인트", theme: .sunset,   thumbnailUrl: nil, distanceKm: 3.5),
        SpotListItem(spotId: 6, name: "광나루 윤슬길",    theme: .reflection, thumbnailUrl: nil, distanceKm: 4.1),
        SpotListItem(spotId: 7, name: "노들섬 노을 뷰",   theme: .sunset,     thumbnailUrl: nil, distanceKm: 4.7),
        SpotListItem(spotId: 8, name: "성수 한강 윤슬",   theme: .reflection, thumbnailUrl: nil, distanceKm: 5.3),
    ]

    func fetchArchiveInfo() async throws -> ArchiveInfo {
        ArchiveInfo(archiveName: "나의 보관함", archiveImageUrl: nil)
    }

    func renameArchive(_ name: String) async throws -> ArchiveInfo {
        ArchiveInfo(archiveName: name, archiveImageUrl: nil)
    }

    func uploadArchiveImage(_ data: Data) async throws -> ArchiveInfo {
        ArchiveInfo(archiveName: "나의 보관함", archiveImageUrl: nil)
    }

    func fetchSavedSpots(page: Int, latitude: Double?, longitude: Double?) async throws -> SpotListPage {
        SpotListPage(spots: Self.sampleItems, page: page, hasNext: false)
    }
}

final class ArchiveDebugBookmarkService: BookmarkServiceProtocol, Sendable {
    func addBookmark(spotId: Int64) async throws {}
    func deleteBookmark(spotId: Int64) async throws {}
}

final class ArchiveDebugAuthService: AuthServiceProtocol, Sendable {
    private let state: ArchiveDebugSharedState

    init(state: ArchiveDebugSharedState) {
        self.state = state
    }

    func currentAuthState() async -> AuthState {
        state.isSignedIn
            ? .signedIn(AuthToken(accessToken: "debug", refreshToken: "debug"))
            : .signedOut
    }

    func signInWithKakao(accessToken: String) async throws -> TokenResponse {
        TokenResponse(accessToken: "", refreshToken: "", profile: UserProfile(userId: "1", email: nil, nickname: "debug", profileImageUrl: nil, provider: .kakao))
    }
    func signInWithApple(identityToken: String, user: AppleUserInfo?) async throws -> TokenResponse {
        TokenResponse(accessToken: "", refreshToken: "", profile: UserProfile(userId: "1", email: nil, nickname: "debug", profileImageUrl: nil, provider: .apple))
    }
    func refreshToken(_ refreshToken: String) async throws -> AuthToken {
        AuthToken(accessToken: "debug", refreshToken: "debug")
    }
    func signOut() async throws {}
}

// 로그인 성공 여부를 두 서비스가 공유
final class ArchiveDebugSharedState: @unchecked Sendable {
    var isSignedIn: Bool
    init(isSignedIn: Bool) { self.isSignedIn = isSignedIn }
}

final class ArchiveDebugSocialService: SocialLoginServiceProtocol, Sendable {
    private let state: ArchiveDebugSharedState
    init(state: ArchiveDebugSharedState) { self.state = state }
    func signInWithKakao() async throws { state.isSignedIn = true }
    func signInWithApple() async throws { state.isSignedIn = true }
}

final class ArchiveDebugLocationService: LocationServiceProtocol, Sendable {
    func requestAuthorization() {}
    func authorizationStatus() -> CLAuthorizationStatus { .notDetermined }
    func currentLocation() async throws -> Coordinate { Coordinate(latitude: 37.5665, longitude: 126.9780) }
    func startUpdatingLocation() -> AsyncStream<Coordinate> { AsyncStream { _ in } }
}
#endif
