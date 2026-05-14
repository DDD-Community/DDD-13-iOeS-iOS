import SwiftUI

struct WithdrawalView: View {
    @StateObject var viewModel: WithdrawalViewModel
    @Environment(\.dismiss) private var dismiss

    var onWithdrawn: () -> Void = {}

    var body: some View {
        ZStack {
            Color("gray95").ignoresSafeArea()

            switch viewModel.step {
            case .input:
                inputBody

            case .processing:
                ProgressView()
                    .tint(Color("gray0"))

            case .done:
                EmptyView()

            case let .failed(message):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(Color("sunsetOrange"))

                    Text(message)
                        .pretendard(.body(.medium()))
                        .foregroundStyle(Color("gray30"))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color("gray0"))
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("회원탈퇴")
                    .pretendard(.heading(.small))
                    .foregroundStyle(Color("gray0"))
            }
        }
        .onChange(of: viewModel.step) { _, newStep in
            if case .done = newStep {
                onWithdrawn()
                dismiss()
            }
        }
    }

    // MARK: - Input Body

    private var inputBody: some View {
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

    // MARK: - Caution Box

    private var cautionBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("탈퇴 전 꼭 확인해주세요")
                .pretendard(.body(.medium(.bold)))
                .foregroundStyle(Color("sunsetOrange"))

            VStack(alignment: .leading, spacing: 6) {
                cautionRow("탈퇴 시 저장한 스팟, 활동 기록이 모두 삭제돼요.")
                cautionRow("삭제된 데이터는 복구할 수 없어요.")
                cautionRow("동일한 소셜 계정으로 재가입할 수 있어요.")
            }
        }
        .padding(16)
        .background(Color("gray80"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color("sunsetOrange").opacity(0.3), lineWidth: 1)
        )
    }

    private func cautionRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .pretendard(.body(.small()))
                .foregroundStyle(Color("gray40"))

            Text(text)
                .pretendard(.body(.small()))
                .foregroundStyle(Color("gray40"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Reason Section

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("어떤 점이 아쉬우셨나요?")
                .pretendard(.heading(.small))
                .foregroundStyle(Color("gray0"))

            WithdrawalReasonDropdown(
                selectedReason: viewModel.selectedReason,
                isOpen: viewModel.isDropdownOpen,
                onToggle: { viewModel.toggleDropdown() },
                onSelect: { viewModel.selectReason($0) }
            )

            if viewModel.selectedReason == .other {
                TextField(
                    "의견을 자유롭게 남겨주세요",
                    text: $viewModel.otherFeedback,
                    axis: .vertical
                )
                .pretendard(.body(.medium()))
                .foregroundStyle(Color("gray0"))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color("gray80"))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .lineLimit(3...)
            }
        }
    }

    // MARK: - Agreement Row

    private var agreementRow: some View {
        Button {
            viewModel.toggleAgreement()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(
                            viewModel.didAgreeToTerms ? Color("sunsetOrange") : Color("gray50"),
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)

                    if viewModel.didAgreeToTerms {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color("sunsetOrange"))
                            .frame(width: 22, height: 22)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color("gray0"))
                    }
                }

                Text("위 유의사항을 모두 확인했으며 동의합니다.")
                    .pretendard(.body(.medium()))
                    .foregroundStyle(Color("gray20"))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            Task { await viewModel.submitWithdrawal() }
        } label: {
            Text("탈퇴하기")
                .pretendard(.body(.large(.bold)))
                .foregroundStyle(Color("gray0"))
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    viewModel.canSubmit ? Color("sunsetOrange") : Color("gray70")
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSubmit)
    }
}
