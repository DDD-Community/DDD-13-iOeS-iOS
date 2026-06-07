import SwiftUI

/// 탈퇴 이력이 있는 계정으로 재가입 시도 시 노출되는 안내 팝업.
struct RestoreAccountDialog: View {
    /// 서버가 내려준 안내 문구. 없으면 기본 문구를 사용한다.
    var message: String?
    var onCancel: () -> Void = {}
    var onConfirm: () -> Void = {}

    private var titleText: String {
        let trimmed = message?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, trimmed.isEmpty == false {
            return trimmed
        }
        return "기존 탈퇴 이력이 있습니다.\n재가입 하시겠습니까?"
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(UIAsset.Colors.sunsetOrange.color, lineWidth: 2)
                            .frame(width: 28, height: 28)

                        Image(systemName: "questionmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.sunsetOrange)
                    }

                    VStack(spacing: 8) {
                        Text(titleText)
                            .pretendard(.heading(.small))
                            .foregroundStyle(.gray0)
                            .multilineTextAlignment(.center)

                        Text("재가입 시 기존 회원 정보가 복구됩니다.")
                            .pretendard(.body(.medium()))
                            .foregroundStyle(.gray30)
                            .multilineTextAlignment(.center)
                    }
                }

                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("취소")
                            .pretendard(.body(.large(.bold)))
                            .foregroundStyle(.gray80)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(.gray0)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: onConfirm) {
                        Text("재가입")
                            .pretendard(.body(.large(.bold)))
                            .foregroundStyle(.gray0)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(.sunsetOrange)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
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
    RestoreAccountDialog()
}
