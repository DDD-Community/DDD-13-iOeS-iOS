import Foundation

protocol KakaoAuthProviderProtocol: Sendable {
    func obtainAccessToken() async throws -> String
}

@MainActor
func getKakaoAuthProvider() -> KakaoAuthProviderProtocol {
    guard let provider = DIContainerHolder.shared?.resolve(KakaoAuthProviderProtocol.self) else {
        fatalError("KakaoAuthProviderProtocol is not registered in DIContainer")
    }
    return provider
}
