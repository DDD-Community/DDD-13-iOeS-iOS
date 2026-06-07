import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    enum ActiveLoginProvider: Sendable, Equatable {
        case kakao
        case apple
    }

    @Published private(set) var isLoading = false
    @Published private(set) var activeLoginProvider: ActiveLoginProvider?
    @Published private(set) var errorMessage: String?
    @Published private(set) var didSignInSucceed = false
    @Published private(set) var didRequestGuestEntry = false
    @Published private(set) var withdrawnAccountInfo: WithdrawnAccountInfo?

    private let socialLoginService: SocialLoginServiceProtocol

    init(socialLoginService: SocialLoginServiceProtocol) {
        self.socialLoginService = socialLoginService
    }

    // MARK: - Intent

    func signInWithKakaoTapped() async {
        guard !isLoading else { return }
        isLoading = true
        activeLoginProvider = .kakao
        errorMessage = nil
        do {
            try await socialLoginService.signInWithKakao()
            didSignInSucceed = true
        } catch {
            handleSignInError(error)
        }
        isLoading = false
        activeLoginProvider = nil
    }

    func signInWithAppleTapped() async {
        guard !isLoading else { return }
        isLoading = true
        activeLoginProvider = .apple
        errorMessage = nil
        do {
            try await socialLoginService.signInWithApple()
            didSignInSucceed = true
        } catch {
            handleSignInError(error)
        }
        isLoading = false
        activeLoginProvider = nil
    }

    /// 로그인 에러를 처리한다. 재가입 필요면 안내 팝업 상태를 설정한다.
    private func handleSignInError(_ error: Error) {
        if let info = RestoreAccountFlow.info(from: error) {
            withdrawnAccountInfo = info
        } else if let e = error as? APIError {
            e.post()
        } else {
            errorMessage = error.localizedDescription
        }
    }

    func confirmRestoreTapped() async {
        guard let info = withdrawnAccountInfo else { return }
        withdrawnAccountInfo = nil
        isLoading = true
        activeLoginProvider = info.credential.isSocialKakao ? .kakao : .apple
        errorMessage = nil
        do {
            try await RestoreAccountFlow.restore(info, using: socialLoginService)
            didSignInSucceed = true
        } catch let e as APIError {
            e.post()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
        activeLoginProvider = nil
    }

    func cancelRestoreTapped() {
        withdrawnAccountInfo = nil
    }

    func continueAsGuestTapped() {
        didRequestGuestEntry = true
    }

    #if DEBUG
    func applySnapshotState(
        isLoading: Bool = false,
        activeLoginProvider: ActiveLoginProvider? = nil,
        errorMessage: String? = nil,
        didRequestGuestEntry: Bool = false
    ) {
        self.isLoading = isLoading
        self.activeLoginProvider = activeLoginProvider
        self.errorMessage = errorMessage
        self.didRequestGuestEntry = didRequestGuestEntry
    }
    #endif
}

