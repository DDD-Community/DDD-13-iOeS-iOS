import Foundation

protocol SocialLoginServiceProtocol: Sendable {
    func signInWithKakao() async throws
    func signInWithApple() async throws
    func restoreAccount(restoreToken: String) async throws
    func retrySignIn(with credential: ProviderCredential) async throws
}

@MainActor
func getSocialLoginService() -> SocialLoginServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(SocialLoginServiceProtocol.self) else {
        fatalError("SocialLoginServiceProtocol is not registered in DIContainer")
    }
    return service
}
