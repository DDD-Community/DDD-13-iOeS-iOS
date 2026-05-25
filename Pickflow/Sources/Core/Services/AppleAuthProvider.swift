import AuthenticationServices
import Foundation
import UIKit

enum AppleAuthError: LocalizedError {
    case cancelled
    case invalidToken
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .cancelled: "Apple 로그인이 취소되었어요."
        case .invalidToken: "Apple 인증 토큰을 가져오지 못했어요."
        case let .underlying(error): error.localizedDescription
        }
    }
}

final class AppleAuthProvider: NSObject, AppleAuthProviderProtocol, @unchecked Sendable {
    private var continuation: CheckedContinuation<AppleCredential, Error>?

    @MainActor
    func obtainCredential() async throws -> AppleCredential {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

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
        continuation.resume(with: result)
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
              identityToken.isEmpty == false
        else {
            finish(with: .failure(AppleAuthError.invalidToken))
            return
        }

        finish(with: .success(AppleCredential(
            identityToken: identityToken,
            fullName: appleIDCredential.fullName,
            email: appleIDCredential.email
        )))
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
