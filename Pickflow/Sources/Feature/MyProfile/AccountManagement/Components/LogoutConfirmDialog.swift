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
                        .foregroundStyle(.gray95)
                        .multilineTextAlignment(.center)

                    Text("로그아웃해도 내 정보는 그대로 유지돼요.\n다시 로그인하면 언제든 이용할 수 있어요.")
                        .pretendard(.body(.small()))
                        .foregroundStyle(.gray60)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 24)

                Divider()
                    .background(.gray10)

                HStack(spacing: 0) {
                    Button(action: onCancel) {
                        Text("취소")
                            .pretendard(.body(.medium(.bold)))
                            .foregroundStyle(.gray60)
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)

                    Divider()
                        .background(.gray10)
                        .frame(maxHeight: 52)

                    Button(action: onConfirm) {
                        if isLoading {
                            ProgressView()
                                .tint(UIAsset.Colors.gray0.color)
                                .frame(maxWidth: .infinity, minHeight: 52)
                        } else {
                            Text("로그아웃")
                                .pretendard(.body(.medium(.bold)))
                                .foregroundStyle(.sunsetOrange)
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
            }
            .background(.gray0)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    LogoutConfirmDialog()
}
