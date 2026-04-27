import Foundation
import KakaoSDKAuth
import KakaoSDKCommon
import KakaoSDKUser

enum KakaoAuthError: LocalizedError {
    case cancelled
    case loginFailed
    case invalidToken
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .cancelled:
            "카카오 로그인이 취소되었어요."
        case .loginFailed:
            "카카오 로그인에 실패했어요. 다시 시도해 주세요."
        case .invalidToken:
            "카카오 인증 토큰을 가져오지 못했어요."
        case let .underlying(error):
            error.localizedDescription
        }
    }
}

final class KakaoAuthProvider: KakaoAuthProviderProtocol, @unchecked Sendable {
    func obtainAccessToken() async throws -> String {
        if UserApi.isKakaoTalkLoginAvailable() {
            do {
                return try await loginWithKakaoTalk()
            } catch {
                if shouldFallbackToKakaoAccount(from: error) {
                    return try await loginWithKakaoAccount()
                }
                throw map(error)
            }
        } else {
            return try await loginWithKakaoAccount()
        }
    }

    private func loginWithKakaoTalk() async throws -> String {
        let token = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let accessToken = oauthToken?.accessToken, accessToken.isEmpty == false else {
                    continuation.resume(throwing: KakaoAuthError.invalidToken)
                    return
                }

                continuation.resume(returning: accessToken)
            }
        }

        return token
    }

    private func loginWithKakaoAccount() async throws -> String {
        do {
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let accessToken = oauthToken?.accessToken, accessToken.isEmpty == false else {
                        continuation.resume(throwing: KakaoAuthError.invalidToken)
                        return
                    }

                    continuation.resume(returning: accessToken)
                }
            }
        } catch {
            throw map(error)
        }
    }

    private func shouldFallbackToKakaoAccount(from error: Error) -> Bool {
        guard let sdkError = error as? SdkError else {
            return false
        }

        if sdkError.isClientFailed {
            let clientError = sdkError.getClientError().reason
            return clientError != .Cancelled
        }

        if sdkError.isAuthFailed {
            let authError = sdkError.getAuthError().reason
            return authError != .AccessDenied
        }

        return false
    }

    private func map(_ error: Error) -> KakaoAuthError {
        if let kakaoAuthError = error as? KakaoAuthError {
            return kakaoAuthError
        }

        if let sdkError = error as? SdkError {
            if sdkError.isClientFailed {
                let clientError = sdkError.getClientError().reason
                if clientError == .Cancelled {
                    return .cancelled
                }
            }

            if sdkError.isAuthFailed {
                let authError = sdkError.getAuthError().reason
                if authError == .AccessDenied {
                    return .cancelled
                }
            }

            return .underlying(sdkError)
        }

        return .underlying(error)
    }
}
