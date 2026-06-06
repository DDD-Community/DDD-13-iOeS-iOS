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
    func submitWithdrawalReason(reasonType: String, content: String?) async throws {}
    func deleteAccount() async throws {}
}

private final class MockAuthServiceForProfile: AuthServiceProtocol, @unchecked Sendable {
    func signInWithKakao(accessToken: String) async throws -> TokenResponse {
        TokenResponse(accessToken: "", refreshToken: "", profile: UserProfile(userId: "1", email: nil, nickname: "capybara123", profileImageUrl: nil, provider: .kakao))
    }
    func signInWithApple(identityToken: String, user: AppleUserInfo?) async throws -> TokenResponse {
        TokenResponse(accessToken: "", refreshToken: "", profile: UserProfile(userId: "1", email: nil, nickname: "capybara123", profileImageUrl: nil, provider: .apple))
    }
    func refreshToken(_ refreshToken: String) async throws -> AuthToken {
        AuthToken(accessToken: "", refreshToken: "")
    }
    func signOut() async throws {}
    func currentAuthState() async -> AuthState { .signedIn(AuthToken(accessToken: "mock", refreshToken: "mock")) }
    func restoreAccount(restoreToken: String) async throws {}
}

private final class MockSocialLoginServiceForProfile: SocialLoginServiceProtocol, @unchecked Sendable {
    func signInWithKakao() async throws {}
    func signInWithApple() async throws {}
    func restoreAccount(restoreToken: String) async throws {}
    func retrySignIn(with credential: ProviderCredential) async throws {}
}
#endif
