import SwiftUI

/// 앱 최상위 라우팅 컨테이너.
///
/// 인증 상태에 따라 `LoginView`와 홈(현재는 placeholder)을 분기한다.
/// 초기 인증 상태 판정은 `AuthService.currentAuthState()`에 위임하며, 해당 로직은
/// KAN-49(자동 로그인)에서 KeyChain(KAN-48) 기반 실구현으로 대체된다.
struct AppRootView: View {
    @StateObject private var viewModel: AppRootViewModel

    init(authService: AuthServiceProtocol) {
        _viewModel = StateObject(wrappedValue: AppRootViewModel(authService: authService))
    }

    var body: some View {
        Group {
            switch viewModel.authState {
            case .loading:
                SplashView()
            case .signedOut:
                LoginView(
                    viewModel: LoginViewModel(authService: viewModel.authService),
                    onSignInSucceeded: { isNewUser in
                        viewModel.didCompleteSignIn(isNewUser: isNewUser)
                    }
                )
            case .signedIn:
                HomePlaceholderView()
                    .task {
                        // TODO(KAN-50): 위치권한 팝업 삽입 지점.
                        //               홈 최초 진입 시 권한 요청 모달을 띄운다.
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

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func bootstrap() async {
        // 현재는 항상 .signedOut 스텁. KAN-49에서 저장된 토큰 기반 자동 로그인으로 대체.
        let state = await authService.currentAuthState()
        authState = state.toRoute()
    }

    func didCompleteSignIn(isNewUser _: Bool) {
        // TODO(KAN-50): isNewUser == true 인 경우 닉네임 설정 / 온보딩 튜토리얼 등 분기 가능 (§9.4).
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
