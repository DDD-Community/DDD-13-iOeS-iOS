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

    private let authService: AuthServiceProtocol
    private let kakaoAuthProvider: KakaoAuthProviderProtocol
    private let appleAuthProvider: AppleAuthProviderProtocol
    private let tokenStore: TokenStoreProtocol

    init(
        authService: AuthServiceProtocol,
        kakaoAuthProvider: KakaoAuthProviderProtocol,
        appleAuthProvider: AppleAuthProviderProtocol,
        tokenStore: TokenStoreProtocol
    ) {
        self.authService = authService
        self.kakaoAuthProvider = kakaoAuthProvider
        self.appleAuthProvider = appleAuthProvider
        self.tokenStore = tokenStore
    }

    convenience init(
        authService: AuthServiceProtocol,
        kakaoAuthProvider: KakaoAuthProviderProtocol,
        tokenStore: TokenStoreProtocol
    ) {
        self.init(
            authService: authService,
            kakaoAuthProvider: kakaoAuthProvider,
            appleAuthProvider: UnavailableAppleAuthProvider(),
            tokenStore: tokenStore
        )
    }

    // MARK: - Intent

    func signInWithKakaoTapped() async {
        guard !isLoading else { return }
        isLoading = true
        activeLoginProvider = .kakao
        errorMessage = nil

        do {
            // 1) Kakao SDK로 kakaoAccessToken 획득.
            let kakaoAccessToken = try await kakaoAuthProvider.obtainAccessToken()

            // 2) 백엔드 POST /auth/kakao 호출.
            let response = try await authService.signInWithKakao(kakaoAccessToken: kakaoAccessToken)

            // 3) 결과 반영.
            try saveToken(accessToken: response.accessToken, refreshToken: response.refreshToken)
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
            let credential = try await appleAuthProvider.obtainCredential()
            let response = try await authService.signInWithApple(
                identityToken: credential.identityToken,
                nonce: credential.nonce
            )
            try saveToken(accessToken: response.accessToken, refreshToken: response.refreshToken)
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

    private func saveToken(accessToken: String, refreshToken: String) throws {
        let authToken = AuthToken(
            accessToken: accessToken,
            refreshToken: refreshToken
        )
        try tokenStore.save(authToken)
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

private struct UnavailableAppleAuthProvider: AppleAuthProviderProtocol {
    func obtainCredential() async throws -> AppleCredential {
        throw AppleAuthError.invalidToken
    }
}
