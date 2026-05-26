import Foundation
@testable import Pickflow

final class MockArchiveService: ArchiveServiceProtocol, @unchecked Sendable {
    var responder: @Sendable (Int) -> Result<SpotListPage, any Error> = { _ in
        .success(SpotListPage(spots: [], page: 0, hasNext: false))
    }

    private(set) var requestedPages: [Int] = []

    func fetchArchive(page: Int) async throws -> SpotListPage {
        requestedPages.append(page)
        return try responder(page).get()
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
