import SwiftUI
import CoreLocation

/// 앱 최상위 라우팅 컨테이너.
///
/// 부트스트랩 결과에 따라 Splash → (Onboarding) → Login → Main(TabView) 으로 분기한다.
/// 초기 인증 상태 판정은 `AuthService.currentAuthState()`에 위임한다.
/// 온보딩 완료 여부는 `OnboardingCompletionStore`에 위임한다.
struct AppRootView: View {
    @StateObject private var viewModel: AppRootViewModel

    init(
        authService: AuthServiceProtocol,
        kakaoAuthProvider: KakaoAuthProviderProtocol,
        appleAuthProvider: AppleAuthProviderProtocol,
        tokenStore: TokenStoreProtocol,
        locationService: LocationServiceProtocol,
        onboardingCompletionStore: OnboardingCompletionStore
    ) {
        _viewModel = StateObject(
            wrappedValue: AppRootViewModel(
                authService: authService,
                kakaoAuthProvider: kakaoAuthProvider,
                appleAuthProvider: appleAuthProvider,
                tokenStore: tokenStore,
                locationService: locationService,
                onboardingCompletionStore: onboardingCompletionStore
            )
        )
    }

    var body: some View {
        Group {
            switch viewModel.routeState {
            case .loading:
                SplashView()
            case .onboarding:
                OnboardingView(
                    viewModel: OnboardingViewModel(
                        completionStore: viewModel.onboardingCompletionStore
                    ),
                    onOnboardingFinished: viewModel.didCompleteOnboarding
                )
                .transition(.opacity)
            case .signedOut:
                LoginView(
                    viewModel: LoginViewModel(
                        authService: viewModel.authService,
                        kakaoAuthProvider: viewModel.kakaoAuthProvider,
                        appleAuthProvider: viewModel.appleAuthProvider,
                        tokenStore: viewModel.tokenStore
                    ),
                    onSignInSucceeded: viewModel.didCompleteSignIn,
                    isClosable: false
                )
            case .signedIn:
                ContentView()
                    .task {
                        viewModel.prepareLocationPermissionIfNeeded()
                    }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.routeState)
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
        case onboarding
        case signedOut
        case signedIn
    }

    @Published private(set) var routeState: AuthRouteState = .loading

    /// 하위 ViewModel(LoginViewModel, OnboardingViewModel 등) 생성 시 주입용으로 노출.
    /// AppContainer에서 1회 resolve한 인스턴스를 재사용한다.
    let authService: AuthServiceProtocol
    let kakaoAuthProvider: KakaoAuthProviderProtocol
    let appleAuthProvider: AppleAuthProviderProtocol
    let tokenStore: TokenStoreProtocol
    let locationService: LocationServiceProtocol
    let onboardingCompletionStore: OnboardingCompletionStore

    private var didHandleLocationPermission = false

    init(
        authService: AuthServiceProtocol,
        kakaoAuthProvider: KakaoAuthProviderProtocol,
        appleAuthProvider: AppleAuthProviderProtocol,
        tokenStore: TokenStoreProtocol,
        locationService: LocationServiceProtocol,
        onboardingCompletionStore: OnboardingCompletionStore
    ) {
        self.authService = authService
        self.kakaoAuthProvider = kakaoAuthProvider
        self.appleAuthProvider = appleAuthProvider
        self.tokenStore = tokenStore
        self.locationService = locationService
        self.onboardingCompletionStore = onboardingCompletionStore
    }

    func bootstrap() async {
        guard onboardingCompletionStore.hasSeenOnboarding() else {
            routeState = .onboarding
            return
        }
        let state = await authService.currentAuthState()
        routeState = state.toRoute()
    }

    func didCompleteOnboarding() {
        Task { @MainActor in
            let state = await authService.currentAuthState()
            routeState = state.toRoute()
        }
    }

    func didCompleteSignIn() {
        routeState = .signedIn
    }

    func prepareLocationPermissionIfNeeded() {
        guard routeState == .signedIn, !didHandleLocationPermission else { return }
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }

        switch locationService.authorizationStatus() {
        case .notDetermined:
            locationService.requestAuthorization()
        case .restricted, .denied, .authorizedAlways, .authorizedWhenInUse:
            break
        @unknown default:
            break
        }

        didHandleLocationPermission = true
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
