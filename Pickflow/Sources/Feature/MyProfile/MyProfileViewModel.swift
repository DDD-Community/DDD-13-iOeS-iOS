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

    /// 고객센터 1:1 문의 이메일. config API 응답으로 갱신되며, 미반영 시 기본값을 유지한다.
    @Published private(set) var supportEmail: String = MyProfileViewModel.defaultSupportEmail
    /// 약관/정책 문서 목록. config API 응답으로 갱신되며, 미반영 시 기본값을 유지한다.
    @Published private(set) var termsPolicies: [TermsPolicy] = TermsPolicy.fallback

    static let defaultSupportEmail = "pickflow.help@gmail.com"

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
    /// 실패하거나 서버가 값을 내려주지 않으면 기본값을 유지한다(fail-soft).
    private func loadAppConfigIfNeeded() async {
        guard !didLoadAppConfig else { return }
        didLoadAppConfig = true

        guard let policy = try? await appVersionService.fetchIOSVersionPolicy() else { return }
        if let email = policy.supportEmail, !email.isEmpty {
            supportEmail = email
        }
        if let policies = policy.termsPolicies, !policies.isEmpty {
            termsPolicies = policies
        }
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
