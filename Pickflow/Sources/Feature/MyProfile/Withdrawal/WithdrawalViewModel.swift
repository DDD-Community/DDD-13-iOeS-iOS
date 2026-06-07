import Foundation

@MainActor
final class WithdrawalViewModel: ObservableObject {
    enum Step: Equatable {
        case input
        case processing
        case done
        case failed(String)
    }

    @Published private(set) var step: Step = .input
    @Published var selectedReason: WithdrawalReason?
    @Published var isDropdownOpen: Bool = false
    @Published var otherFeedback: String = ""
    @Published var didAgreeToTerms: Bool = false

    var canSubmit: Bool {
        guard let reason = selectedReason, didAgreeToTerms else { return false }
        if reason == .other && otherFeedback.trimmingCharacters(in: .whitespaces).isEmpty {
            return false
        }
        return true
    }

    private let userService: UserServiceProtocol
    private let authService: AuthServiceProtocol

    init(userService: UserServiceProtocol, authService: AuthServiceProtocol) {
        self.userService = userService
        self.authService = authService
    }

    func selectReason(_ reason: WithdrawalReason) {
        selectedReason = reason
        isDropdownOpen = false
    }

    func toggleDropdown() {
        isDropdownOpen.toggle()
    }

    func toggleAgreement() {
        didAgreeToTerms.toggle()
    }

    func submitWithdrawal() async {
        guard canSubmit, let reason = selectedReason else { return }
        step = .processing
        do {
            // 탈퇴 사유 등록 API는 '기타(OTHERS)'일 때만 호출한다.
            if reason == .other {
                let content = otherFeedback.trimmingCharacters(in: .whitespacesAndNewlines)
                try await userService.submitWithdrawalReason(reasonType: "OTHERS", content: content)
            }
            try await userService.deleteAccount()
            try await authService.signOut()
            step = .done
            NotificationCenter.default.post(name: .userDidWithdraw, object: nil)
        } catch let e as APIError {
            step = .input
            e.post()
        } catch {
            step = .failed(error.localizedDescription)
        }
    }
}
