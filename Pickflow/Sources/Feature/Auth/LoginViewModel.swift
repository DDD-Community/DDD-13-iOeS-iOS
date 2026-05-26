import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    enum ActiveLoginProvider: Sendable, Equatable {
        case kakao
        case apple
    }

    struct WithdrawnAccountInfo {
        let restoreToken: String
        let credential: ProviderCredential
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
        } catch AuthError.withdrawalRestoreRequired(let restoreToken, let credential) {
            withdrawnAccountInfo = WithdrawnAccountInfo(restoreToken: restoreToken, credential: credential)
        } catch {
            errorMessage = error.localizedDescription
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
        } catch AuthError.withdrawalRestoreRequired(let restoreToken, let credential) {
            withdrawnAccountInfo = WithdrawnAccountInfo(restoreToken: restoreToken, credential: credential)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
        activeLoginProvider = nil
    }

    func confirmRestoreTapped() async {
        guard let info = withdrawnAccountInfo else { return }
        withdrawnAccountInfo = nil
        isLoading = true
        activeLoginProvider = info.credential.isSocialKakao ? .kakao : .apple
        errorMessage = nil
        do {
            try await socialLoginService.restoreAccount(restoreToken: info.restoreToken)
            try await socialLoginService.retrySignIn(with: info.credential)
            didSignInSucceed = true
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

