import SwiftUI

/// 비로그인 사용자가 앱 진입 시 만나는 온보딩/로그인 화면.
struct LoginView: View {
    @StateObject var viewModel: LoginViewModel

    /// 로그인 성공 시 상위(`AppRootView`)로 전파되는 콜백.
    var onSignInSucceeded: () -> Void = {}

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack {
                header
                Spacer()
                centerContent
                    .padding(.bottom, 108)
                Spacer()
                bottomCTA
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 66)
        }
        .preferredColorScheme(.dark)
        .onChange(of: viewModel.didSignInSucceed) { _, succeeded in
            if succeeded {
                onSignInSucceeded()
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

    private var backgroundGradient: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 181 / 255, green: 127 / 255, blue: 0 / 255), location: 0),
                .init(color: Color(red: 188 / 255, green: 59 / 255, blue: 0 / 255), location: 0.2),
                .init(color: Color(red: 15 / 255, green: 23 / 255, blue: 40 / 255), location: 0.5),
                .init(color: Color(red: 19 / 255, green: 20 / 255, blue: 22 / 255), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("PICKFLOW")
                .font(.custom(PretendardFontName.bold, size: 24))
                .tracking(1.2)
                .foregroundStyle(.gray0)
                .frame(width: 140, height: 32, alignment: .leading)
                .accessibilityLabel("PICKFLOW")

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Center Content

    private var centerContent: some View {
        VStack(spacing: 24) {
            appLogo

            VStack(spacing: 12) {
                Text("일상 속 반짝임,\n실패 없이 포착하세요")
                    .pretendard(.display(.large))
                    .foregroundStyle(.gray0)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text("파편화된 포토스팟 정보는 이제 그만.\n정확한 일몰 시간과 촬영 팁을 한눈에 보세요.")
                    .pretendard(.body(.large()))
                    .foregroundStyle(.gray20)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: 295)
    }

    private var appLogo: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color("gray0"))

            if UIImage(named: "ic_flare") != nil {
                Image("ic_flare")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color(red: 188 / 255, green: 59 / 255, blue: 0 / 255))
            }
        }
        .frame(width: 60, height: 60)
        .accessibilityHidden(true)
    }

    // MARK: - Bottom CTA

    private var bottomCTA: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                KakaoLoginButton(isLoading: viewModel.activeLoginProvider == .kakao) {
                    Task { await viewModel.signInWithKakaoTapped() }
                }
                .disabled(viewModel.isLoading)

                AppleLoginButton(isLoading: viewModel.activeLoginProvider == .apple) {
                    Task { await viewModel.signInWithAppleTapped() }
                }
                .disabled(viewModel.isLoading)
            }

            Button {
                viewModel.continueAsGuestTapped()
            } label: {
                Text("비회원으로 시작하기")
                    .pretendard(.body(.medium()))
                    .underline()
                    .foregroundStyle(Color(red: 177 / 255, green: 184 / 255, blue: 190 / 255))
                    .frame(minHeight: 25)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: 358)
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

// MARK: - Preview

#Preview("LoginView") {
    LoginView(
        viewModel: LoginViewModel(
            authService: PreviewAuthService(),
            kakaoAuthProvider: PreviewKakaoAuthProvider(),
            tokenStore: PreviewTokenStore()
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

    func signInWithApple(identityToken _: String, nonce _: String) async throws -> AppleSignInResponse {
        try await Task.sleep(nanoseconds: 500_000_000)
        return AppleSignInResponse(
            accessToken: "preview",
            refreshToken: "preview",
            isNewUser: false,
            user: AuthUser(id: 1, nickname: "preview", socialProvider: .apple)
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

private final class PreviewTokenStore: TokenStoreProtocol, @unchecked Sendable {
    func save(_: AuthToken) throws {}

    func load() throws -> AuthToken? { nil }

    func clear() throws {}
}
