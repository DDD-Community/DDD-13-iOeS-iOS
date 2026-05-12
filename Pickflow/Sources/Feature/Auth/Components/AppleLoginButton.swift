import SwiftUI

struct AppleLoginButton: View {
    let isLoading: Bool
    let action: () -> Void

    init(isLoading: Bool = false, action: @escaping () -> Void) {
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color("gray0"))

                if isLoading {
                    ProgressView()
                        .tint(Color("gray90"))
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 21, weight: .medium))
                            .foregroundStyle(Color("gray90"))
                            .frame(width: 24, height: 24)

                        Text("Apple로 로그인")
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
        .accessibilityLabel("Apple 계정으로 로그인")
    }
}

#Preview {
    VStack(spacing: 16) {
        AppleLoginButton {}
        AppleLoginButton(isLoading: true) {}
    }
    .padding()
    .background(Color("gray100"))
}
