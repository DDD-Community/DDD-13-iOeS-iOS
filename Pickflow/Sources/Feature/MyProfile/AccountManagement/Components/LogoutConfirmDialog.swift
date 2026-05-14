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
                        .foregroundStyle(Color("gray95"))
                        .multilineTextAlignment(.center)

                    Text("로그아웃해도 내 정보는 그대로 유지돼요.\n다시 로그인하면 언제든 이용할 수 있어요.")
                        .pretendard(.body(.small()))
                        .foregroundStyle(Color("gray60"))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 24)

                Divider()
                    .background(Color("gray10"))

                HStack(spacing: 0) {
                    Button(action: onCancel) {
                        Text("취소")
                            .pretendard(.body(.medium(.bold)))
                            .foregroundStyle(Color("gray60"))
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)

                    Divider()
                        .background(Color("gray10"))
                        .frame(maxHeight: 52)

                    Button(action: onConfirm) {
                        if isLoading {
                            ProgressView()
                                .tint(Color("gray0"))
                                .frame(maxWidth: .infinity, minHeight: 52)
                        } else {
                            Text("로그아웃")
                                .pretendard(.body(.medium(.bold)))
                                .foregroundStyle(Color("sunsetOrange"))
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
            }
            .background(Color("gray0"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    LogoutConfirmDialog()
}
