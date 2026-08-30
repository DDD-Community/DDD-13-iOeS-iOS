import Foundation
@testable import Pickflow

final class MockArchiveService: ArchiveServiceProtocol, @unchecked Sendable {
    var responder: @Sendable (Int) -> Result<SavedSpotPage, any Error> = { _ in
        .success(SavedSpotPage(spots: [], page: 0, hasNext: false))
    }

    var mySpotsResponder: @Sendable (Int) -> Result<MySpotListPage, any Error> = { _ in
        .success(MySpotListPage(spots: [], page: 0, hasNext: false))
    }

    private(set) var requestedPages: [Int] = []
    private(set) var requestedMySpotPages: [Int] = []

    var archiveInfo = ArchiveInfo(archiveName: "테스트 아카이브", archiveImageUrl: nil)

    func fetchArchiveInfo() async throws -> ArchiveInfo {
        archiveInfo
    }

    func fetchSavedSpots(page: Int, latitude _: Double?, longitude _: Double?) async throws -> SavedSpotPage {
        requestedPages.append(page)
        return try responder(page).get()
    }

    func fetchMySpots(page: Int, latitude _: Double?, longitude _: Double?) async throws -> MySpotListPage {
        requestedMySpotPages.append(page)
        return try mySpotsResponder(page).get()
    }

    func renameArchive(_: String) async throws -> ArchiveInfo {
        fatalError("not used in archive tests")
    }

    func uploadArchiveImage(_: Data) async throws -> ArchiveInfo {
        fatalError("not used in archive tests")
    }
}

final class MockSocialLoginService: SocialLoginServiceProtocol, @unchecked Sendable {
    var kakaoError: (any Error)?
    var appleError: (any Error)?
    private(set) var kakaoCallCount = 0
    private(set) var appleCallCount = 0

    func signInWithKakao() async throws {
        kakaoCallCount += 1
        if let kakaoError { throw kakaoError }
    }

    func signInWithApple() async throws {
        appleCallCount += 1
        if let appleError { throw appleError }
    }

    func restoreAccount(restoreToken: String) async throws {}
    func retrySignIn(with credential: ProviderCredential) async throws {}
}

final class MockAuthServiceForArchive: AuthServiceProtocol, @unchecked Sendable {
    var stubbedAuthState: AuthState = .signedOut

    func currentAuthState() async -> AuthState { stubbedAuthState }

    func signOut() async throws {}

    func signInWithKakao(accessToken: String) async throws -> TokenResponse {
        fatalError("not used in archive tests")
    }

    func signInWithApple(identityToken: String, user: AppleUserInfo?) async throws -> TokenResponse {
        fatalError("not used in archive tests")
    }

    func refreshToken(_ refreshToken: String) async throws -> AuthToken {
        fatalError("not used in archive tests")
    }

    func restoreAccount(restoreToken: String) async throws {
        fatalError("not used in archive tests")
    }
}

extension SavedSpotItem {
    static func fixture(
        spotId: Int64 = 1,
        name: String = "한강 노을 스팟",
        theme: SpotTheme? = .sunset,
        imageUrl: String? = "https://example.com/spot.jpg",
        distanceKm: Double? = 1.2,
        deleted: Bool = false,
        isPrivate: Bool? = nil
    ) -> SavedSpotItem {
        SavedSpotItem(
            spotId: spotId,
            name: name,
            theme: theme,
            imageUrl: imageUrl,
            latitude: 37.5,
            longitude: 127.0,
            distanceKm: distanceKm,
            savedAt: "2026-08-01T00:00:00Z",
            deleted: deleted,
            isPrivate: isPrivate
        )
    }
}

extension MySpotListItem {
    static func fixture(
        spotId: Int64 = 1,
        name: String = "석촌호수 산책길",
        theme: SpotTheme? = .reflection,
        status: MySpotStatus = .draft,
        distanceKm: Double? = 1.2
    ) -> MySpotListItem {
        MySpotListItem(
            spotId: spotId,
            name: name,
            theme: theme,
            imageUrl: nil,
            latitude: 37.5,
            longitude: 127.0,
            distanceKm: distanceKm,
            createdAt: "2026-04-11",
            status: status,
            bookmarkCount: 0
        )
    }
}
