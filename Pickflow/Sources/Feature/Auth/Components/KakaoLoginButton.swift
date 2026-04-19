import SwiftUI

/// 카카오 공식 가이드라인에 근접한 옐로우 CTA 버튼.
///
/// - Note: 카카오 공식 심볼 이미지 사용 의무 여부는 §9 리소스 요청 확인 필요.
///   현재는 SF Symbol(`message.fill`)을 플레이스홀더로 사용한다.
struct KakaoLoginButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    init(
        title: String = "카카오로 시작하기",
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
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.kakaoYellow)
                    .frame(height: 56)

                if isLoading {
                    ProgressView()
                        .tint(Color("gray100"))
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color("gray100"))
                        Text(title)
                            .pretendard(.body(.large(.bold)))
                            .foregroundStyle(Color("gray100"))
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .opacity(isLoading ? 0.85 : 1.0)
        .accessibilityLabel("카카오 계정으로 로그인")
    }
}

// MARK: - Colors

extension Color {
    /// 카카오 공식 옐로우 `#FEE500`.
    static let kakaoYellow = Color(red: 254 / 255, green: 229 / 255, blue: 0 / 255)
}

#Preview {
    VStack(spacing: 16) {
        KakaoLoginButton {}
        KakaoLoginButton(isLoading: true) {}
    }
    .padding()
    .background(Color("gray100"))
}
