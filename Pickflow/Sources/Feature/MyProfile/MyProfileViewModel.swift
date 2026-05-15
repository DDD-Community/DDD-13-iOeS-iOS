import Foundation

@MainActor
final class MyProfileViewModel: ObservableObject {
    enum LoadState: Equatable {
        case signedOut
        case loading
        case signedIn(User)
        case failed(String)
    }

    @Published private(set) var state: LoadState = .loading
    @Published var isNavigatingToAccountManagement = false
    @Published private(set) var isLoginLoading = false
    @Published private(set) var loginError: String?

    let userService: UserServiceProtocol
    let authService: AuthServiceProtocol
    private let socialLoginService: SocialLoginServiceProtocol

    init(
        userService: UserServiceProtocol,
        authService: AuthServiceProtocol,
        socialLoginService: SocialLoginServiceProtocol
    ) {
        self.userService = userService
        self.authService = authService
        self.socialLoginService = socialLoginService
    }

    func onAppear() async {
        let authState = await authService.currentAuthState()
        guard case .signedIn = authState else {
            state = .signedOut
            return
        }
        await fetchUser()
    }

    func refresh() async {
        await fetchUser()
    }

    func signInWithKakao() async {
        guard !isLoginLoading else { return }
        isLoginLoading = true
        loginError = nil
        do {
            try await socialLoginService.signInWithKakao()
            await onAppear()
        } catch {
            loginError = error.localizedDescription
        }
        isLoginLoading = false
    }

    func signInWithApple() async {
        guard !isLoginLoading else { return }
        isLoginLoading = true
        loginError = nil
        do {
            try await socialLoginService.signInWithApple()
            await onAppear()
        } catch {
            loginError = error.localizedDescription
        }
        isLoginLoading = false
    }

    func navigateToAccountManagement() {
        isNavigatingToAccountManagement = true
    }

    func handleSignedOut() {
        state = .signedOut
    }

    #if DEBUG
    func applySignedInState(user: User) {
        state = .signedIn(user)
    }
    #endif

    private func fetchUser() async {
        state = .loading
        do {
            let user = try await userService.fetchCurrentUser()
            state = .signedIn(user)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
