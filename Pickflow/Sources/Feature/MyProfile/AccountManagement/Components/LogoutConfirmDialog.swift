import SwiftUI

struct LogoutConfirmDialog: View {
    var onCancel: () -> Void = {}
    var onConfirm: () -> Void = {}
    var isLoading: Bool = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("잠시 로그아웃하시겠어요?")
                        .pretendard(.heading(.small))
                        .foregroundStyle(.gray0)
                        .multilineTextAlignment(.center)

                    Text("로그아웃해도 내 정보는 그대로 유지돼요.\n다시 로그인하면 언제든 이용할 수 있어요.")
                        .pretendard(.body(.small()))
                        .foregroundStyle(.gray30)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 24)

                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("취소")
                            .pretendard(.body(.medium(.bold)))
                            .foregroundStyle(.gray30)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(.gray80)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)

                    Button(action: onConfirm) {
                        if isLoading {
                            ProgressView()
                                .tint(UIAsset.Colors.gray0.color)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(.sunsetOrange)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        } else {
                            Text("로그아웃")
                                .pretendard(.body(.medium(.bold)))
                                .foregroundStyle(.gray0)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(.sunsetOrange)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(.gray90)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    LogoutConfirmDialog()
}
