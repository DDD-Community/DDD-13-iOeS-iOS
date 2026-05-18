import SwiftUI

struct ArchiveSignedOutContent: View {
    let isLoading: Bool
    var onKakaoTap: () -> Void = {}
    var onAppleTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                centerContent
                if isLoading {
                    ProgressView()
                        .tint(UIAsset.Colors.gray0.color)
                        .frame(height: 96)
                } else {
                    bottomCTA
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }

    private var centerContent: some View {
        VStack(spacing: 12) {
            Text("보관함 이용을 위해\n로그인이 필요해요")
                .pretendard(.heading(.large))
                .foregroundStyle(.gray0)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text("로그인하면 저장한 스팟을\n한 곳에서 확인할 수 있어요.")
                .pretendard(.body(.medium()))
                .foregroundStyle(.gray40)
                .multilineTextAlignment(.center)
        }
    }

    private var bottomCTA: some View {
        VStack(spacing: 12) {
            KakaoLoginButton(action: onKakaoTap)
            AppleLoginButton(action: onAppleTap)
        }
        .frame(maxWidth: 358)
    }
}

#Preview {
    ZStack {
        UIAsset.Colors.gray95.color.ignoresSafeArea()
        ArchiveSignedOutContent(isLoading: false)
    }
}
