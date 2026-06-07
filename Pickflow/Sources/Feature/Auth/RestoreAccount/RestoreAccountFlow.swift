import SwiftUI

/// 탈퇴 이력이 있는 계정으로 재가입 시도 시 서버가 내려주는 정보.
struct WithdrawnAccountInfo {
    let restoreToken: String
    let message: String?
    let credential: ProviderCredential
}

/// 소셜 로그인 중 "재가입 필요(U007)" 응답을 감지하고 복구를 처리하는 공통 로직.
///
/// 로그인 진입점(로그인 화면 / 보관 탭 / 마이 탭)에서 동일하게 재사용한다.
enum RestoreAccountFlow {
    /// 로그인 에러가 재가입 필요면 안내 정보를 반환한다. 아니면 nil.
    static func info(from error: Error) -> WithdrawnAccountInfo? {
        guard case let AuthError.withdrawalRestoreRequired(restoreToken, message, credential) = error else {
            return nil
        }
        return WithdrawnAccountInfo(restoreToken: restoreToken, message: message, credential: credential)
    }

    /// 재가입 확정: 계정 복구 후 동일 자격으로 재로그인한다.
    static func restore(_ info: WithdrawnAccountInfo, using service: SocialLoginServiceProtocol) async throws {
        try await service.restoreAccount(restoreToken: info.restoreToken)
        try await service.retrySignIn(with: info.credential)
    }
}

extension View {
    /// 재가입 안내 팝업을 공통으로 노출한다.
    /// `info`가 nil이 아니면 `RestoreAccountDialog`를 오버레이로 띄운다.
    func restoreAccountPrompt(
        info: WithdrawnAccountInfo?,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () -> Void
    ) -> some View {
        overlay {
            if let info {
                RestoreAccountDialog(
                    message: info.message,
                    onCancel: onCancel,
                    onConfirm: onConfirm
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: info != nil)
    }
}
