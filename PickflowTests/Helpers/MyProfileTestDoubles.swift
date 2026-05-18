import Foundation
@testable import Pickflow

final class MockUserService: UserServiceProtocol, @unchecked Sendable {
    var fetchResult: Result<User, any Error> = .success(.fixture())
    var updateResult: Result<User, any Error> = .success(.fixture())
    var deleteError: (any Error)?

    private(set) var fetchCallCount = 0
    private(set) var updateCalls: [(nickname: String?, profileImageData: Data?)] = []
    private(set) var deleteCallCount: Int = 0

    func fetchCurrentUser() async throws -> User {
        fetchCallCount += 1
        return try fetchResult.get()
    }

    func updateProfile(nickname: String?, profileImageData: Data?) async throws -> User {
        updateCalls.append((nickname, profileImageData))
        return try updateResult.get()
    }

    func deleteAccount() async throws {
        deleteCallCount += 1
        if let deleteError { throw deleteError }
    }
}

final class MockAuthServiceForProfile: AuthServiceProtocol, @unchecked Sendable {
    var stubbedAuthState: AuthState = .signedOut
    var signOutError: (any Error)?
    private(set) var signOutCallCount = 0

    func currentAuthState() async -> AuthState { stubbedAuthState }

    func signOut() async throws {
        signOutCallCount += 1
        if let signOutError { throw signOutError }
    }

    func signInWithKakao(kakaoAccessToken: String) async throws -> KakaoSignInResponse {
        fatalError("not used in profile tests")
    }

    func signInWithApple(identityToken: String, nonce: String) async throws -> AppleSignInResponse {
        fatalError("not used in profile tests")
    }

    func refreshToken(_ refreshToken: String) async throws -> AuthToken {
        fatalError("not used in profile tests")
    }
}
