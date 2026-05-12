import AuthenticationServices
import CryptoKit
import Foundation
import Security
import UIKit

enum AppleAuthError: LocalizedError {
    case cancelled
    case invalidToken
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .cancelled:
            "Apple 로그인이 취소되었어요."
        case .invalidToken:
            "Apple 인증 토큰을 가져오지 못했어요."
        case let .underlying(error):
            error.localizedDescription
        }
    }
}

final class AppleAuthProvider: NSObject, AppleAuthProviderProtocol, @unchecked Sendable {
    private var continuation: CheckedContinuation<AppleCredential, Error>?
    private var currentNonce: String?

    @MainActor
    func obtainCredential() async throws -> AppleCredential {
        let rawNonce = Self.makeNonce()
        currentNonce = rawNonce

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(rawNonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
            }
        } onCancel: {
            Task { @MainActor in
                self.finish(with: .failure(AppleAuthError.cancelled))
            }
        }
    }

    @MainActor
    private func finish(with result: Result<AppleCredential, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        currentNonce = nil
        continuation.resume(with: result)
    }

    private static func makeNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            guard status == errSecSuccess else {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(status).")
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < UInt8(charset.count) {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }
}

extension AppleAuthProvider: ASAuthorizationControllerDelegate {
    @MainActor
    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = appleIDCredential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8),
              identityToken.isEmpty == false,
              let currentNonce
        else {
            finish(with: .failure(AppleAuthError.invalidToken))
            return
        }

        finish(with: .success(AppleCredential(identityToken: identityToken, nonce: currentNonce)))
    }

    @MainActor
    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        if let authorizationError = error as? ASAuthorizationError,
           authorizationError.code == .canceled
        {
            finish(with: .failure(AppleAuthError.cancelled))
        } else {
            finish(with: .failure(AppleAuthError.underlying(error)))
        }
    }
}

extension AppleAuthProvider: ASAuthorizationControllerPresentationContextProviding {
    @MainActor
    func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
