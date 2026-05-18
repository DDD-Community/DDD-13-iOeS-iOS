import SnapshotTesting
import SwiftUI
import UIKit
import XCTest

@testable import Pickflow

@MainActor
final class MyProfileSnapshotTests: XCTestCase {

    // MARK: - Trait Helpers

    private static let light = UITraitCollection(userInterfaceStyle: .light)
    private static let dark = UITraitCollection(userInterfaceStyle: .dark)
    private static let a11yLight = UITraitCollection(traitsFrom: [
        UITraitCollection(userInterfaceStyle: .light),
        UITraitCollection(preferredContentSizeCategory: .accessibilityExtraLarge),
    ])

    private typealias L = MyProfileSnapshotTests

    // MARK: - My Profile: Signed Out

    func test_my_profile_signedout_light() {
        assertSnapshot(
            of: signedOutScreen(),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_my_profile_signedout_dark() {
        assertSnapshot(
            of: signedOutScreen(),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    func test_my_profile_signedout_a11y() {
        assertSnapshot(
            of: signedOutScreen(),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.a11yLight)
        )
    }

    // MARK: - My Profile: Loading

    func test_my_profile_loading_light() {
        assertSnapshot(
            of: loadingScreen(),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_my_profile_loading_dark() {
        assertSnapshot(
            of: loadingScreen(),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - My Profile: Signed In (no profile image)

    func test_my_profile_signedin_noimage_light() {
        assertSnapshot(
            of: signedInScreen(user: .fixture(profileImageURL: nil)),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_my_profile_signedin_noimage_dark() {
        assertSnapshot(
            of: signedInScreen(user: .fixture(profileImageURL: nil)),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - My Profile: Signed In (with profile image)

    func test_my_profile_signedin_withimage_light() {
        assertSnapshot(
            of: signedInScreen(user: .fixture(profileImageURL: URL(string: "https://example.com/avatar.jpg")!)),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_my_profile_signedin_withimage_dark() {
        assertSnapshot(
            of: signedInScreen(user: .fixture(profileImageURL: URL(string: "https://example.com/avatar.jpg")!)),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - My Profile: Failed

    func test_my_profile_failed_light() {
        assertSnapshot(
            of: failedScreen(message: "네트워크 연결을 확인해주세요."),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_my_profile_failed_dark() {
        assertSnapshot(
            of: failedScreen(message: "네트워크 연결을 확인해주세요."),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - Account Management: Idle (save disabled)

    func test_account_mgmt_idle_light() {
        assertSnapshot(
            of: accountMgmtScreen(nicknameDraft: "capybara123", isSaveEnabled: false),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_account_mgmt_idle_dark() {
        assertSnapshot(
            of: accountMgmtScreen(nicknameDraft: "capybara123", isSaveEnabled: false),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - Account Management: Dirty (save enabled)

    func test_account_mgmt_dirty_light() {
        assertSnapshot(
            of: accountMgmtScreen(nicknameDraft: "newname_draft", isSaveEnabled: true),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_account_mgmt_dirty_dark() {
        assertSnapshot(
            of: accountMgmtScreen(nicknameDraft: "newname_draft", isSaveEnabled: true),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - Account Management: Logout Dialog

    func test_account_mgmt_logout_dialog_light() {
        assertSnapshot(
            of: logoutDialogScreen(),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_account_mgmt_logout_dialog_dark() {
        assertSnapshot(
            of: logoutDialogScreen(),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - Account Management: Logout Processing

    func test_account_mgmt_logout_processing_light() {
        assertSnapshot(
            of: logoutDialogScreen(isLoading: true),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    // MARK: - Account Management: a11y

    func test_account_mgmt_a11y() {
        assertSnapshot(
            of: accountMgmtScreen(nicknameDraft: "capybara123", isSaveEnabled: false),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.a11yLight)
        )
    }

    // MARK: - Withdrawal: Initial (no reason, no agree)

    func test_withdrawal_initial_light() {
        assertSnapshot(
            of: withdrawalScreen(),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_withdrawal_initial_dark() {
        assertSnapshot(
            of: withdrawalScreen(),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - Withdrawal: Dropdown Open

    func test_withdrawal_dropdown_open_light() {
        assertSnapshot(
            of: withdrawalScreen(isDropdownOpen: true),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_withdrawal_dropdown_open_dark() {
        assertSnapshot(
            of: withdrawalScreen(isDropdownOpen: true),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - Withdrawal: Reason Selected, Not Agreed

    func test_withdrawal_reason_selected_light() {
        assertSnapshot(
            of: withdrawalScreen(selectedReason: .rarelyUsed),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_withdrawal_reason_selected_dark() {
        assertSnapshot(
            of: withdrawalScreen(selectedReason: .rarelyUsed),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - Withdrawal: Ready (reason + agreed)

    func test_withdrawal_ready_light() {
        assertSnapshot(
            of: withdrawalScreen(selectedReason: .rarelyUsed, didAgree: true),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_withdrawal_ready_dark() {
        assertSnapshot(
            of: withdrawalScreen(selectedReason: .rarelyUsed, didAgree: true),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - Withdrawal: Other, Empty Text

    func test_withdrawal_other_empty_light() {
        assertSnapshot(
            of: withdrawalScreen(selectedReason: .other, otherFeedback: "", didAgree: true),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    // MARK: - Withdrawal: Other, Filled Text

    func test_withdrawal_other_filled_light() {
        assertSnapshot(
            of: withdrawalScreen(selectedReason: .other, otherFeedback: "개선 의견이에요", didAgree: true),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_withdrawal_other_filled_dark() {
        assertSnapshot(
            of: withdrawalScreen(selectedReason: .other, otherFeedback: "개선 의견이에요", didAgree: true),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - Withdrawal: Processing

    func test_withdrawal_processing_light() {
        assertSnapshot(
            of: withdrawalProcessingScreen(),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    // MARK: - Withdrawal: a11y

    func test_withdrawal_a11y() {
        assertSnapshot(
            of: withdrawalScreen(),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.a11yLight)
        )
    }

    // MARK: - View Factories

    private func signedOutScreen() -> some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()
            MyProfileSignedOutContent()
        }
        .snapshotEnvironment(colorScheme: .dark)
    }

    private func loadingScreen() -> some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()
            ProgressView()
                .tint(UIAsset.Colors.gray0.color)
        }
    }

    private func signedInScreen(user: User) -> some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()
            MyProfileSignedInContent(user: user)
        }
        .snapshotEnvironment(colorScheme: .dark)
    }

    private func failedScreen(message: String) -> some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.sunsetOrange)

                Text(message)
                    .pretendard(.body(.medium()))
                    .foregroundStyle(.gray30)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
        }
    }

    private func accountMgmtScreen(nicknameDraft: String, isSaveEnabled: Bool) -> some View {
        AccountManagementPreviewView(
            nicknameDraft: nicknameDraft,
            isSaveEnabled: isSaveEnabled
        )
        .snapshotEnvironment(colorScheme: .dark)
    }

    private func logoutDialogScreen(isLoading: Bool = false) -> some View {
        ZStack {
            accountMgmtScreenBackground(nicknameDraft: "capybara123")
            LogoutConfirmDialog(isLoading: isLoading)
        }
        .snapshotEnvironment(colorScheme: .dark)
    }

    private func accountMgmtScreenBackground(nicknameDraft: String) -> some View {
        AccountManagementPreviewView(nicknameDraft: nicknameDraft, isSaveEnabled: false)
            .allowsHitTesting(false)
    }

    private func withdrawalScreen(
        selectedReason: WithdrawalReason? = nil,
        isDropdownOpen: Bool = false,
        otherFeedback: String = "",
        didAgree: Bool = false
    ) -> some View {
        WithdrawalPreviewView(
            selectedReason: selectedReason,
            isDropdownOpen: isDropdownOpen,
            otherFeedback: otherFeedback,
            didAgree: didAgree
        )
        .snapshotEnvironment(colorScheme: .dark)
    }

    private func withdrawalProcessingScreen() -> some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()
            ProgressView()
                .tint(UIAsset.Colors.gray0.color)
        }
    }
}

// MARK: - Preview Helpers (snapshot-only rendering without ViewModel async)

private struct AccountManagementPreviewView: View {
    let nicknameDraft: String
    let isSaveEnabled: Bool
    var user: User = .fixture()

    var body: some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        profileImageSection
                        nicknameSection
                        socialSection

                        Divider().background(.gray80)

                        accountActionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private var navBar: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.gray0)
                .frame(width: 44, height: 44)

            Spacer()

            Text("계정 관리")
                .pretendard(.heading(.small))
                .foregroundStyle(.gray0)

            Spacer()

            Text("저장")
                .pretendard(.body(.medium(.bold)))
                .foregroundStyle(isSaveEnabled ? UIAsset.Colors.sunsetOrange.color : UIAsset.Colors.gray50.color)
                .frame(width: 44, height: 44)
        }
    }

    private var profileImageSection: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(.gray80)
                .frame(width: 96, height: 96)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(.gray50)
                )

            Circle()
                .fill(.gray80)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "camera.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.gray0)
                )
                .offset(x: 2, y: 2)
        }
    }

    private var nicknameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("닉네임")
                .pretendard(.label(.medium))
                .foregroundStyle(.gray40)

            Text(nicknameDraft)
                .pretendard(.body(.large()))
                .foregroundStyle(.gray0)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.gray80)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var socialSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("연결된 소셜")
                .pretendard(.label(.medium))
                .foregroundStyle(.gray40)

            HStack {
                Text("카카오로 로그인됨")
                    .pretendard(.body(.medium()))
                    .foregroundStyle(.gray20)

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.sunsetOrange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.gray80)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var accountActionsSection: some View {
        VStack(spacing: 0) {
            Text("로그아웃")
                .pretendard(.body(.medium()))
                .foregroundStyle(.gray40)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 16)

            Text("회원탈퇴")
                .pretendard(.body(.medium()))
                .foregroundStyle(Color.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 16)
        }
    }
}

private struct WithdrawalPreviewView: View {
    let selectedReason: WithdrawalReason?
    let isDropdownOpen: Bool
    let otherFeedback: String
    let didAgree: Bool

    var canSubmit: Bool {
        guard let reason = selectedReason, didAgree else { return false }
        if reason == .other && otherFeedback.trimmingCharacters(in: .whitespaces).isEmpty { return false }
        return true
    }

    var body: some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        cautionBox
                        reasonSection
                        agreementRow
                        submitButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private var navBar: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.gray0)
                .frame(width: 44, height: 44)

            Spacer()

            Text("회원탈퇴")
                .pretendard(.heading(.small))
                .foregroundStyle(.gray0)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var cautionBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("탈퇴 전 꼭 확인해주세요")
                .pretendard(.body(.medium(.bold)))
                .foregroundStyle(.sunsetOrange)

            VStack(alignment: .leading, spacing: 6) {
                cautionRow("탈퇴 시 저장한 스팟, 활동 기록이 모두 삭제돼요.")
                cautionRow("삭제된 데이터는 복구할 수 없어요.")
                cautionRow("동일한 소셜 계정으로 재가입할 수 있어요.")
            }
        }
        .padding(16)
        .background(.gray80)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(UIAsset.Colors.sunsetOrange.color.opacity(0.3), lineWidth: 1)
        )
    }

    private func cautionRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•").pretendard(.body(.small())).foregroundStyle(.gray40)
            Text(text).pretendard(.body(.small())).foregroundStyle(.gray40)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("어떤 점이 아쉬우셨나요?")
                .pretendard(.heading(.small))
                .foregroundStyle(.gray0)

            WithdrawalReasonDropdown(
                selectedReason: selectedReason,
                isOpen: isDropdownOpen
            )

            if selectedReason == .other {
                let placeholder = "의견을 자유롭게 남겨주세요"
                ZStack(alignment: .topLeading) {
                    if otherFeedback.isEmpty {
                        Text(placeholder)
                            .pretendard(.body(.medium()))
                            .foregroundStyle(.gray50)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                    }
                    Text(otherFeedback.isEmpty ? " " : otherFeedback)
                        .pretendard(.body(.medium()))
                        .foregroundStyle(.gray0)
                        .opacity(otherFeedback.isEmpty ? 0 : 1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .background(.gray80)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private var agreementRow: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(
                        didAgree ? UIAsset.Colors.sunsetOrange.color : UIAsset.Colors.gray50.color,
                        lineWidth: 1.5
                    )
                    .frame(width: 22, height: 22)

                if didAgree {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(.sunsetOrange)
                        .frame(width: 22, height: 22)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.gray0)
                }
            }

            Text("위 유의사항을 모두 확인했으며 동의합니다.")
                .pretendard(.body(.medium()))
                .foregroundStyle(.gray20)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    private var submitButton: some View {
        Text("탈퇴하기")
            .pretendard(.body(.large(.bold)))
            .foregroundStyle(.gray0)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(canSubmit ? UIAsset.Colors.sunsetOrange.color : UIAsset.Colors.gray70.color)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
