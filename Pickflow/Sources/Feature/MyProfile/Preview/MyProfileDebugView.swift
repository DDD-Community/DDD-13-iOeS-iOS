import SwiftUI

#if DEBUG
struct MyProfileDebugView: View {
    var body: some View {
        ContentView(initialTab: .my)
    }
}

struct MyProfileSignedInDebugView: View {
    private let viewModel: MyProfileViewModel = {
        let vm = MyProfileViewModel(
            userService: MockUserService(),
            authService: MockAuthServiceForProfile(),
            socialLoginService: MockSocialLoginServiceForProfile()
        )
        vm.applySignedInState(user: .fixture())
        return vm
    }()

    var body: some View {
        ContentView(initialTab: .my, myProfileViewModel: viewModel)
    }
}

// MARK: - Mocks

private final class MockUserService: UserServiceProtocol, @unchecked Sendable {
    func fetchCurrentUser() async throws -> User { .fixture() }
    func updateProfile(nickname: String?, profileImageData: Data?) async throws -> User { .fixture(nickname: nickname ?? "capybara123") }
    func deleteAccount() async throws {}
}

private final class MockAuthServiceForProfile: AuthServiceProtocol, @unchecked Sendable {
    func signInWithKakao(kakaoAccessToken: String) async throws -> KakaoSignInResponse {
        KakaoSignInResponse(accessToken: "", refreshToken: "", isNewUser: false, user: AuthUser(id: 1, nickname: "capybara123", socialProvider: .kakao))
    }
    func signInWithApple(identityToken: String, nonce: String) async throws -> AppleSignInResponse {
        AppleSignInResponse(accessToken: "", refreshToken: "", isNewUser: false, user: AuthUser(id: 1, nickname: "capybara123", socialProvider: .apple))
    }
    func refreshToken(_ refreshToken: String) async throws -> AuthToken {
        AuthToken(accessToken: "", refreshToken: "")
    }
    func signOut() async throws {}
    func currentAuthState() async -> AuthState { .signedIn(AuthToken(accessToken: "mock", refreshToken: "mock")) }
}

private final class MockSocialLoginServiceForProfile: SocialLoginServiceProtocol, @unchecked Sendable {
    func signInWithKakao() async throws {}
    func signInWithApple() async throws {}
}
#endif
