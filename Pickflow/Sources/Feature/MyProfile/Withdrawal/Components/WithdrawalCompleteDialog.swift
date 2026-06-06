import SwiftUI

struct WithdrawalCompleteDialog: View {
    var onConfirm: () -> Void = {}

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.sunsetOrange)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.gray0)
                    }

                    VStack(spacing: 8) {
                        Text("탈퇴가 완료되었습니다.")
                            .pretendard(.heading(.small))
                            .foregroundStyle(.gray0)
                            .multilineTextAlignment(.center)

                        Text("Pickflow는 비회원으로도 이용\n가능하니 언제든 다시 찾아와주세요!")
                            .pretendard(.body(.medium()))
                            .foregroundStyle(.gray30)
                            .multilineTextAlignment(.center)
                    }
                }

                Button(action: onConfirm) {
                    Text("확인")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(.gray0)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(.sunsetOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 16)
            .background(.gray90)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    WithdrawalCompleteDialog()
}
