import SwiftUI

struct WithdrawalReasonDropdown: View {
    let selectedReason: WithdrawalReason?
    let isOpen: Bool
    var onToggle: () -> Void = {}
    var onSelect: (WithdrawalReason) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            header

            if isOpen {
                Rectangle()
                    .fill(UIAsset.Colors.gray70.color)
                    .frame(height: 1)

                reasonList
            }
        }
        .background(.gray90)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Header

    private var header: some View {
        Button(action: onToggle) {
            HStack {
                Text(selectedReason?.displayText ?? "탈퇴 사유를 선택해주세요")
                    .pretendard(.body(.medium()))
                    .foregroundStyle(
                        selectedReason != nil ? UIAsset.Colors.gray0.color : UIAsset.Colors.gray50.color
                    )

                Spacer()

                Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.gray40)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("탈퇴 사유 선택")
        .accessibilityValue(selectedReason?.displayText ?? "미선택")
    }

    // MARK: - Reason List

    private var reasonList: some View {
        VStack(spacing: 0) {
            ForEach(WithdrawalReason.allCases) { reason in
                reasonRow(reason: reason)

                if reason != WithdrawalReason.allCases.last {
                    Rectangle()
                        .fill(UIAsset.Colors.gray70.color)
                        .frame(height: 1)
                }
            }
        }
    }

    private func reasonRow(reason: WithdrawalReason) -> some View {
        Button {
            onSelect(reason)
        } label: {
            HStack {
                Text(reason.displayText)
                    .pretendard(.body(.medium()))
                    .foregroundStyle(
                        selectedReason == reason ? UIAsset.Colors.sunsetOrange.color : UIAsset.Colors.gray0.color
                    )

                Spacer()

                if selectedReason == reason {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.sunsetOrange)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        WithdrawalReasonDropdown(selectedReason: nil, isOpen: false)
        WithdrawalReasonDropdown(selectedReason: .rarelyUsed, isOpen: true)
    }
    .padding()
    .background(.gray95)
}
