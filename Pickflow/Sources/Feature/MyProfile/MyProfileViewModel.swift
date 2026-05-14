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

    let userService: UserServiceProtocol
    let authService: AuthServiceProtocol

    init(userService: UserServiceProtocol, authService: AuthServiceProtocol) {
        self.userService = userService
        self.authService = authService
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

    func navigateToAccountManagement() {
        isNavigatingToAccountManagement = true
    }

    func handleSignedOut() {
        state = .signedOut
    }

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
