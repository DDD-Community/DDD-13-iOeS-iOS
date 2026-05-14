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
        let feedback = reason == .other ? otherFeedback.trimmingCharacters(in: .whitespaces) : nil
        do {
            try await userService.deleteAccount(reason: reason.rawValue, otherFeedback: feedback)
            try await authService.signOut()
            step = .done
        } catch {
            step = .failed(error.localizedDescription)
        }
    }
}
