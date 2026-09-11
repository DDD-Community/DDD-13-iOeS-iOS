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
    @Published var isNavigatingToNotice = false
    @Published var isNavigatingToTermsAndPolicy = false
    @Published private(set) var isLoginLoading = false
    @Published private(set) var loginError: String?
    @Published private(set) var withdrawnAccountInfo: WithdrawnAccountInfo?

    /// 고객센터 1:1 문의 이메일. config API 응답으로 채워지며, 서버가 내려주기 전까지는 `nil`.
    @Published private(set) var supportEmail: String?
    /// 약관/정책 문서 목록. config API 응답으로 채워지며, 서버가 내려주기 전까지는 빈 배열.
    @Published private(set) var termsPolicies: [TermsPolicy] = []

    let userService: UserServiceProtocol
    let authService: AuthServiceProtocol
    private let socialLoginService: SocialLoginServiceProtocol
    private let appVersionService: AppVersionServiceProtocol

    private var didLoadAppConfig = false

    nonisolated(unsafe) private var notificationObservers: [NSObjectProtocol] = []

    init(
        userService: UserServiceProtocol,
        authService: AuthServiceProtocol,
        socialLoginService: SocialLoginServiceProtocol,
        appVersionService: AppVersionServiceProtocol
    ) {
        self.userService = userService
        self.authService = authService
        self.socialLoginService = socialLoginService
        self.appVersionService = appVersionService
        setupNotificationObservers()
    }

    deinit {
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // 화면 재진입 시에는 이미 로드된 데이터를 유지하고,
    // 실제 변경 이벤트(노티피케이션)에만 반응해 갱신한다.
    func onAppear() async {
        await loadAppConfigIfNeeded()

        if case .signedIn = state { return }

        let authState = await authService.currentAuthState()
        guard case .signedIn = authState else {
            state = .signedOut
            return
        }
        await fetchUser()
    }

    /// 약관/정책 URL과 고객센터 이메일을 config API에서 한 번 받아 캐시한다.
    private func loadAppConfigIfNeeded() async {
        guard !didLoadAppConfig else { return }
        didLoadAppConfig = true

        guard let policy = try? await appVersionService.fetchIOSVersionPolicy() else { return }
        supportEmail = policy.supportEmail
        termsPolicies = policy.termsPolicies ?? []
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
            handleSignInError(error)
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
            handleSignInError(error)
        }
        isLoginLoading = false
    }

    /// 로그인 에러 처리. 재가입 필요면 안내 팝업 상태를 설정한다.
    private func handleSignInError(_ error: Error) {
        if let info = RestoreAccountFlow.info(from: error) {
            withdrawnAccountInfo = info
        } else if let e = error as? APIError {
            e.post()
        } else {
            loginError = error.localizedDescription
        }
    }

    func confirmRestore() async {
        guard let info = withdrawnAccountInfo else { return }
        withdrawnAccountInfo = nil
        isLoginLoading = true
        loginError = nil
        do {
            try await RestoreAccountFlow.restore(info, using: socialLoginService)
            await onAppear()
        } catch let e as APIError {
            e.post()
        } catch {
            loginError = error.localizedDescription
        }
        isLoginLoading = false
    }

    func cancelRestore() {
        withdrawnAccountInfo = nil
    }

    func navigateToAccountManagement() {
        isNavigatingToAccountManagement = true
    }

    func navigateToNotice() {
        isNavigatingToNotice = true
    }

    func navigateToTermsAndPolicy() {
        isNavigatingToTermsAndPolicy = true
    }

    func handleSignedOut() {
        state = .signedOut
    }

    private func setupNotificationObservers() {
        let refreshTriggers: [Notification.Name] = [
            .userProfileDidUpdate,
            .spotBookmarkDidChange,
            .mySpotListDidChange,
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
