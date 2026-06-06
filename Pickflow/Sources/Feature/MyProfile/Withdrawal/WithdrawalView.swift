import SwiftUI

struct WithdrawalView: View {
    @StateObject var viewModel: WithdrawalViewModel
    @Environment(\.dismiss) private var dismiss

    var onWithdrawn: () -> Void = {}

    var body: some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()

            VStack(spacing: 0) {
                customHeader

                switch viewModel.step {
                case .input:
                    inputBody

                case .processing:
                    Spacer()
                    ProgressView()
                        .tint(UIAsset.Colors.gray0.color)
                    Spacer()

                case .done:
                    doneBody

                case let .failed(message):
                    Spacer()
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
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.25), value: viewModel.step)
    }

    /// 탈퇴 완료 후 로그인 화면으로 빠져나간다.
    private func completeAndExit() {
        onWithdrawn()
        dismiss()
    }

    // MARK: - Done Body

    private var doneBody: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("탈퇴가 완료되었어요.")
                    .pretendard(.heading(.medium))
                    .foregroundStyle(.gray30)

                Text("이용해 주셔서 감사합니다.")
                    .pretendard(.body(.large()))
                    .foregroundStyle(.gray50)
            }
            .multilineTextAlignment(.center)

            Spacer().frame(height: 56)

            Button {
                completeAndExit()
            } label: {
                Text("로그인 화면으로 이동")
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(.gray0)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(.sunsetOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Custom Header

    private var customHeader: some View {
        HStack {
            Button {
                if case .done = viewModel.step {
                    completeAndExit()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.gray0)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("회원탈퇴")
                .pretendard(.heading(.small))
                .foregroundStyle(.gray0)

            Spacer()

            Color.clear.frame(width: 17, height: 17)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Input Body

    private var inputBody: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 48) {
                    cautionSection
                    reasonSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.immediately)

            bottomSection
        }
    }

    // MARK: - Caution Section

    private var cautionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("탈퇴 유의사항 안내")
                .pretendard(.heading(.small))
                .foregroundStyle(.gray0)

            (Text("탈퇴할 경우 서비스에서 저장한 스팟 및 활동 기록을\n더 이상 확인할 수 없습니다. 계정 정보와 기록은 ")
                .foregroundColor(UIAsset.Colors.gray0.color)
            + Text("일정 기간(1년) 보관 후 파기")
                .foregroundColor(UIAsset.Colors.sunsetOrange.color)
            + Text("되며, 이후에는 ")
                .foregroundColor(UIAsset.Colors.gray0.color)
            + Text("복구가 불가능")
                .foregroundColor(UIAsset.Colors.sunsetOrange.color)
            + Text("하니 신중하게 결정해주세요.")
                .foregroundColor(UIAsset.Colors.gray0.color))
                .pretendard(.body(.medium()))
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(16)
                .background(.gray80)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Reason Section

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("어떤 점이 아쉬우셨나요?")
                    .pretendard(.heading(.small))
                    .foregroundStyle(.gray0)

                Text("소중한 의견을 바탕으로\n더 나은 서비스 경험을 만들어가겠습니다.")
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray40)
            }

            WithdrawalReasonDropdown(
                selectedReason: viewModel.selectedReason,
                isOpen: viewModel.isDropdownOpen,
                onToggle: { viewModel.toggleDropdown() },
                onSelect: { viewModel.selectReason($0) }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(UIAsset.Colors.gray50.color, lineWidth: 1)
            )
            .padding(.top, 12)

            if viewModel.selectedReason == .other {
                TextField(
                    "사용하시면서 아쉬웠던 점을 알려주세요",
                    text: $viewModel.otherFeedback,
                    axis: .vertical
                )
                .pretendard(.body(.medium()))
                .foregroundStyle(.gray0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(16)
                .frame(height: 300)
                .background(.gray95)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(UIAsset.Colors.gray50.color, lineWidth: 1)
                )
                .overlay(alignment: .bottomTrailing) {
                    HStack(spacing: 0) {
                        Text("\(viewModel.otherFeedback.count)")
                            .foregroundStyle(.gray0)
                        Text("/200")
                            .foregroundStyle(.gray50)
                    }
                    .pretendard(.label(.medium))
                    .padding([.trailing, .bottom], 16)
                }
                .onChange(of: viewModel.otherFeedback) { _, newValue in
                    if newValue.count > 200 {
                        viewModel.otherFeedback = String(newValue.prefix(200))
                    }
                }
                .padding(.top, 24)
            }
        }
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: 12) {
            agreementRow
            submitButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 32)
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
                            viewModel.didAgreeToTerms ? UIAsset.Colors.sunsetOrange.color : UIAsset.Colors.gray0.color,
                            lineWidth: 1
                        )
                        .frame(width: 22, height: 22)

                    if viewModel.didAgreeToTerms {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(.sunsetOrange)
                            .frame(width: 22, height: 22)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.gray0)
                    }
                }

                Text("안내사항을 모두 확인하였으며 이에 동의합니다.")
                    .pretendard(.body(.medium()))
                    .foregroundStyle(.gray0)
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
                .foregroundStyle(.gray0)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    viewModel.canSubmit ? UIAsset.Colors.sunsetOrange.color : UIAsset.Colors.gray70.color
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSubmit)
    }
}
