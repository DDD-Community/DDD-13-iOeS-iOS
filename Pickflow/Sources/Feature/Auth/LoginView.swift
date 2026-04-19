import SwiftUI

/// 비로그인 사용자가 앱 진입 시 만나는 온보딩/로그인 화면.
///
/// - Note: 로고 이미지(`AppLogoMark`), 글로우 컬러, 헤드라인 카피 등은 §9 리소스 요청 확정 필요.
struct LoginView: View {
    @StateObject var viewModel: LoginViewModel

    /// 로그인 성공 시 상위(`AppRootView`)로 전파되는 콜백.
    /// - Parameter isNewUser: 신규 가입 여부. `is_new_user: true` 분기 처리에 사용.
    var onSignInSucceeded: (_ isNewUser: Bool) -> Void = { _ in }

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
        .onChange(of: viewModel.didSignInSucceed) { _, succeeded in
            if succeeded {
                onSignInSucceeded(viewModel.isNewUser)
            }
        }
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

            Circle()
                .fill(Color.loginTopGlow)
                .frame(width: 366, height: 388)
                .blur(radius: 120)
                .offset(x: -132, y: -70)

            Circle()
                .fill(Color.loginBottomGlow)
                .frame(width: 234, height: 248)
                .blur(radius: 96)
                .offset(x: 118, y: 188)
        }
    }

    // MARK: - Center Content

    private var centerContent: some View {
        VStack(spacing: 0) {
            appLogo
                .padding(.bottom, 32)

            Text("일상 속 반짝임,\n실패 없이 포착하세요")
                .pretendard(.display(.medium))
                .foregroundStyle(Color("gray0"))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 32)

            Text("파편화된 포토스팟 정보는 이제 그만.\n정확한 일몰 시간과 촬영 팁을 한눈에 보세요.")
                .pretendard(.body(.small()))
                .foregroundStyle(Color("gray10"))
                .multilineTextAlignment(.center)
        }
    }

    /// 앱 로고 마크. 실제 에셋(`AppLogoMark`)이 없는 환경에서는 SF Symbol로 플레이스홀더 렌더.
    private var appLogo: some View {
        Group {
            if UIImage(named: "AppLogoMark") != nil {
                Image("AppLogoMark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                // TODO(resource): Assets.xcassets/AppLogoMark.imageset 교체 필요 (§9.2).
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.loginLogoBackground)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color("gray0"))
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
        .padding(.bottom, 60)
    }

    // MARK: - Helpers

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in
                // alert dismiss 시 상태를 강제로 소거할 별도 메서드는 두지 않는다.
                // 다음 사용자 액션에서 ViewModel이 새 상태로 덮어쓴다.
            }
        )
    }
}

// MARK: - Colors

private extension Color {
    /// 디자인 시스템 `gray100` 기반 배경.
    static let loginBackground = Color("gray100")

    /// Figma 좌상단 블러 글로우.
    static let loginTopGlow = Color(red: 88 / 255, green: 88 / 255, blue: 88 / 255)
        .opacity(0.36)

    /// Figma 우하단 오렌지 블러 글로우.
    static let loginBottomGlow = Color(red: 204 / 255, green: 78 / 255, blue: 22 / 255)
        .opacity(0.42)

    /// 로고 placeholder 배경색.
    static let loginLogoBackground = Color(red: 255 / 255, green: 106 / 255, blue: 42 / 255)
}

// MARK: - Preview

#Preview("LoginView") {
    LoginView(
        viewModel: LoginViewModel(
            authService: PreviewAuthService(),
            kakaoAuthProvider: PreviewKakaoAuthProvider()
        )
    )
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

private final class PreviewKakaoAuthProvider: KakaoAuthProviderProtocol, @unchecked Sendable {
    func obtainAccessToken() async throws -> String {
        "preview-kakao-access-token"
    }
}
