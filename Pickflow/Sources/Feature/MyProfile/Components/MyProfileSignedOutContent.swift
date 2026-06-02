import SwiftUI

struct MyProfileSignedOutContent: View {
    var onKakaoLoginTap: () -> Void = {}
    var onAppleLoginTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            header

            Spacer()

            VStack(spacing: 32) {
                centerContent
                bottomCTA
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 66)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            PickflowWorkMarkLogo()

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Center

    private var centerContent: some View {
        VStack(spacing: 12) {
            Text("마이페이지 이용을 위해\n로그인이 필요해요")
                .pretendard(.heading(.large))
                .foregroundStyle(.gray0)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text("로그인하면 내 스팟을 저장하고\n일몰 알림을 받을 수 있어요.")
                .pretendard(.body(.medium()))
                .foregroundStyle(.gray40)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Bottom CTA

    private var bottomCTA: some View {
        VStack(spacing: 12) {
            KakaoLoginButton(action: onKakaoLoginTap)
            AppleLoginButton(action: onAppleLoginTap)
        }
        .frame(maxWidth: 358)
    }
}

#Preview {
    ZStack {
        UIAsset.Colors.gray95.color.ignoresSafeArea()
        MyProfileSignedOutContent()
    }
}
