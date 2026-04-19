import SwiftUI

/// 비로그인 사용자가 앱 진입 시 만나는 온보딩/로그인 화면.
///
/// - Note: 로고 이미지(`AppLogoMark`), 글로우 컬러, 헤드라인 카피 등은 §9 리소스 요청 확정 필요.
struct LoginView: View {
    @StateObject var viewModel: LoginViewModel

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack {
                Spacer(minLength: 0)
                centerContent
                Spacer(minLength: 0)
                bottomCTA
            }
            .padding(.horizontal, 20)
        }
        .preferredColorScheme(.dark)
        .alert(
            "로그인 실패",
            isPresented: errorAlertBinding,
            presenting: viewModel.errorMessage
        ) { _ in
            Button("확인", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Background

    /// 다크 배경 위에 중앙~하단으로 퍼지는 웜 오렌지/레드 레이디얼 글로우.
    /// HEX 확정값은 §9 리소스 요청 확인 필요 (현재는 추정치).
    private var backgroundGradient: some View {
        ZStack {
            Color.loginBackground
            RadialGradient(
                colors: [Color.loginGlowCenter, Color.loginGlowEdge.opacity(0)],
                center: .center,
                startRadius: 40,
                endRadius: 340
            )
            .blendMode(.plusLighter)
        }
    }

    // MARK: - Center Content

    private var centerContent: some View {
        VStack(spacing: 0) {
            appLogo
                .padding(.bottom, 32)

            Text("일상 속 반짝임,\n실패 없이 포착하세요")
                .pretendard(.display(.medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 12)

            Text("파편화된 포토스팟 정보는 이제 그만.\n정확한 일몰 시간과 촬영 팁을 한눈에 보세요.")
                .pretendard(.body(.small()))
                .foregroundStyle(Color.loginSubtitle)
                .multilineTextAlignment(.center)
        }
    }

    /// 앱 로고 마크. 실제 에셋(`AppLogoMark`)이 없는 환경에서는 SF Symbol로 플레이스홀더 렌더.
    private var appLogo: some View {
        Group {
            if let uiImage = UIImage(named: "AppLogoMark") {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                // TODO(resource): Assets.xcassets/AppLogoMark.imageset 교체 필요 (§9.2).
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.loginGlowCenter)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: 72, height: 72)
        .accessibilityHidden(true)
    }

    // MARK: - Bottom CTA

    private var bottomCTA: some View {
        KakaoLoginButton(isLoading: viewModel.isLoading) {
            Task { await viewModel.signInWithKakaoTapped() }
        }
        .padding(.bottom, 16)
    }

    // MARK: - Helpers

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    // 현재 VM은 읽기 전용이므로 메시지 소거 전용 메서드가 필요하면 별도 티켓에서 분리.
                    // 본 티켓에서는 alert dismiss 후 자연 복구를 허용한다.
                }
            }
        )
    }
}

// MARK: - Colors

private extension Color {
    /// 배경 베이스 `#0B0B0B` (§9 확정 대기).
    static let loginBackground = Color(red: 11 / 255, green: 11 / 255, blue: 11 / 255)

    /// 글로우 중심색 `#FF6A2A` (§9 확정 대기).
    static let loginGlowCenter = Color(red: 255 / 255, green: 106 / 255, blue: 42 / 255)

    /// 글로우 외곽 페이드아웃 지점 `#B22A00` (§9 확정 대기).
    static let loginGlowEdge = Color(red: 178 / 255, green: 42 / 255, blue: 0 / 255)

    /// 서브카피 그레이 `#B8B8B8`.
    static let loginSubtitle = Color(red: 184 / 255, green: 184 / 255, blue: 184 / 255)
}

// MARK: - Preview

#Preview("LoginView") {
    LoginView(viewModel: LoginViewModel(authService: PreviewAuthService()))
}

/// Preview 렌더를 위한 인라인 Mock.
/// - Note: 실제 실행 환경에서는 `AppContainer`가 주입한 `AuthService`가 사용된다.
private final class PreviewAuthService: AuthServiceProtocol, @unchecked Sendable {
    func signInWithKakao(kakaoAccessToken _: String) async throws -> KakaoSignInResponse {
        try await Task.sleep(nanoseconds: 500_000_000)
        return KakaoSignInResponse(
            accessToken: "preview",
            refreshToken: "preview",
            isNewUser: false,
            user: AuthUser(id: 1, nickname: "preview", socialProvider: .kakao)
        )
    }

    func refreshToken(_: String) async throws -> AuthToken {
        AuthToken(accessToken: "preview", refreshToken: "preview")
    }

    func signOut() async throws {}

    func currentAuthState() async -> AuthState { .signedOut }
}
