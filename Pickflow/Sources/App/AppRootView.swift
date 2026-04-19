import SwiftUI

/// 앱 최상위 라우팅 컨테이너.
///
/// 인증 상태에 따라 `LoginView`와 홈(현재는 placeholder)을 분기한다.
/// 초기 인증 상태 판정은 `AuthService.currentAuthState()`에 위임하며, 해당 로직은
/// KAN-49(자동 로그인)에서 KeyChain(KAN-48) 기반 실구현으로 대체된다.
struct AppRootView: View {
    @StateObject private var viewModel: AppRootViewModel

    init(
        authService: AuthServiceProtocol,
        kakaoAuthProvider: KakaoAuthProviderProtocol,
        tokenStore: TokenStoreProtocol
    ) {
        _viewModel = StateObject(
            wrappedValue: AppRootViewModel(
                authService: authService,
                kakaoAuthProvider: kakaoAuthProvider,
                tokenStore: tokenStore
            )
        )
    }

    var body: some View {
        Group {
            switch viewModel.authState {
            case .loading:
                SplashView()
            case .signedOut:
                LoginView(
                    viewModel: LoginViewModel(
                        authService: viewModel.authService,
                        kakaoAuthProvider: viewModel.kakaoAuthProvider,
                        tokenStore: viewModel.tokenStore
                    ),
                    onSignInSucceeded: { isNewUser in
                        viewModel.didCompleteSignIn(isNewUser: isNewUser)
                    }
                )
            case .signedIn:
                HomePlaceholderView()
                    .task {
                        // TODO(KAN-46): 홈 최초 진입 시 위치권한 온보딩 삽입.
                    }
            }
        }
        .task {
            await viewModel.bootstrap()
        }
    }
}

// MARK: - ViewModel

@MainActor
final class AppRootViewModel: ObservableObject {
    enum AuthRouteState: Equatable {
        case loading
        case signedOut
        case signedIn
    }

    @Published private(set) var authState: AuthRouteState = .loading

    /// LoginView 생성 시 주입용으로 노출. AppContainer에서 1회 resolve한 인스턴스를 재사용한다.
    let authService: AuthServiceProtocol
    let kakaoAuthProvider: KakaoAuthProviderProtocol
    let tokenStore: TokenStoreProtocol

    init(
        authService: AuthServiceProtocol,
        kakaoAuthProvider: KakaoAuthProviderProtocol,
        tokenStore: TokenStoreProtocol
    ) {
        self.authService = authService
        self.kakaoAuthProvider = kakaoAuthProvider
        self.tokenStore = tokenStore
    }

    func bootstrap() async {
        let state = await authService.currentAuthState()
        authState = state.toRoute()
    }

    func didCompleteSignIn(isNewUser: Bool) {
        if isNewUser {
            // TODO(KAN-46): 신규 유저 온보딩 분기.
        }
        authState = .signedIn
    }
}

private extension AuthState {
    func toRoute() -> AppRootViewModel.AuthRouteState {
        switch self {
        case .signedOut: .signedOut
        case .signedIn: .signedIn
        }
    }
}

// MARK: - Placeholder Screens

/// 자동 로그인 판정이 끝나기 전까지 잠깐 노출되는 스플래시.
private struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ProgressView()
                .tint(.white)
        }
    }
}

/// 로그인 후 진입할 홈 화면 플레이스홀더. 본 티켓 범위 밖.
private struct HomePlaceholderView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("Home (WIP)")
                .foregroundStyle(.white)
                .font(.largeTitle)
        }
    }
}
