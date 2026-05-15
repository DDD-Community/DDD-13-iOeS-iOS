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
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
        activeLoginProvider = nil
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

