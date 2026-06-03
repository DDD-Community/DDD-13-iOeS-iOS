import Foundation
import UIKit

@MainActor
final class MyProfileViewModel: ObservableObject {
    enum LoadState: Equatable {
        case signedOut
        case loading
        case signedIn(User)
        case failed(String)
    }

    @Published private(set) var state: LoadState = .loading
    @Published private(set) var cachedProfileImage: UIImage?
    @Published var isNavigatingToAccountManagement = false
    @Published private(set) var isLoginLoading = false
    @Published private(set) var loginError: String?

    let userService: UserServiceProtocol
    let authService: AuthServiceProtocol
    private let socialLoginService: SocialLoginServiceProtocol

    nonisolated(unsafe) private var notificationObservers: [NSObjectProtocol] = []

    init(
        userService: UserServiceProtocol,
        authService: AuthServiceProtocol,
        socialLoginService: SocialLoginServiceProtocol
    ) {
        self.userService = userService
        self.authService = authService
        self.socialLoginService = socialLoginService
        setupNotificationObservers()
    }

    deinit {
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // 화면 재진입 시에는 이미 로드된 데이터를 유지하고,
    // 실제 변경 이벤트(노티피케이션)에만 반응해 갱신한다.
    func onAppear() async {
        if case .signedIn = state { return }

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
        } catch let e as APIError {
            e.post()
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
        } catch let e as APIError {
            e.post()
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

    private func setupNotificationObservers() {
        let refreshTriggers: [Notification.Name] = [
            .userProfileDidUpdate,
            .spotBookmarkDidChange,
            .spotDidRegister,
        ]
        let signOutTriggers: [Notification.Name] = [
            .userDidSignOut,
            .userDidWithdraw,
        ]

        notificationObservers = refreshTriggers.map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, case .signedIn = self.state else { return }
                    await self.refresh()
                }
            }
        } + signOutTriggers.map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.handleSignedOut()
                }
            }
        }
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
            await cacheProfileImageIfNeeded(urlString: user.profileImageUrl)
        } catch let e as APIError {
            state = .failed(e.message)
            e.post()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func cacheProfileImageIfNeeded(urlString: String?) async {
        guard let urlString, let url = URL(string: urlString) else { return }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data) else { return }
        cachedProfileImage = image
    }
}
