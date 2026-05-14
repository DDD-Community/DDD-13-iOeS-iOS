import SwiftUI

struct MyProfileSignedOutContent: View {
    var onKakaoLoginTap: () -> Void = {}
    var onAppleLoginTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            header

            Spacer()

            centerContent

            Spacer()

            bottomCTA
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 66)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image("pickflow_wordmark")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 140, height: 32, alignment: .leading)
                .accessibilityLabel("PICKFLOW")

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Center

    private var centerContent: some View {
        VStack(spacing: 12) {
            Text("마이페이지 이용을 위해\n로그인이 필요해요")
                .pretendard(.heading(.large))
                .foregroundStyle(Color("gray0"))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text("로그인하면 내 스팟을 저장하고\n일몰 알림을 받을 수 있어요.")
                .pretendard(.body(.medium()))
                .foregroundStyle(Color("gray40"))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 108)
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
        Color("gray95").ignoresSafeArea()
        MyProfileSignedOutContent()
    }
}
