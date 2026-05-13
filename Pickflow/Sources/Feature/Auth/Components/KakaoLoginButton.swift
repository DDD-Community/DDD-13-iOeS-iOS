import SwiftUI

/// 카카오 로그인 CTA 버튼.
struct KakaoLoginButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    init(
        title: String = "카카오로 로그인",
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.kakaoYellow)

                if isLoading {
                    ProgressView()
                        .tint(Color("gray90"))
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color("gray90"))
                        Text(title)
                            .pretendard(.body(.large(.bold)))
                            .foregroundStyle(Color("gray90"))
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 56)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .opacity(isLoading ? 0.85 : 1.0)
        .accessibilityLabel("카카오 계정으로 로그인")
    }
}

// MARK: - Colors

extension Color {
    /// Figma 1067:5060 `#FEE404`.
    static let kakaoYellow = Color(red: 254 / 255, green: 228 / 255, blue: 4 / 255)
}

#Preview {
    VStack(spacing: 16) {
        KakaoLoginButton {}
        KakaoLoginButton(isLoading: true) {}
    }
    .padding()
    .background(Color("gray100"))
}
