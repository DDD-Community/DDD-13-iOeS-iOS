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
        socialLoginService: SocialLoginServiceProtocol,
        locationService: LocationServiceProtocol,
        onboardingCompletionStore: OnboardingCompletionStore,
        newFeatureGuideStore: NewFeatureGuideStore
    ) {
        _viewModel = StateObject(
            wrappedValue: AppRootViewModel(
                authService: authService,
                socialLoginService: socialLoginService,
                locationService: locationService,
                onboardingCompletionStore: onboardingCompletionStore,
                newFeatureGuideStore: newFeatureGuideStore
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
                        socialLoginService: viewModel.socialLoginService
                    ),
                    onSignInSucceeded: viewModel.didCompleteSignIn,
                    isClosable: false
                )
            case .signedIn:
                ContentView(onSignedOut: viewModel.didSignOut)
                    .task {
                        viewModel.prepareLocationPermissionIfNeeded()
                    }
            }
        }
        .overlay {
            if viewModel.isV2UpdateGuidePresented {
                V2UpdateGuideModal(onConfirm: viewModel.didConfirmV2UpdateGuide)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.routeState)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isV2UpdateGuidePresented)
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
    @Published private(set) var isV2UpdateGuidePresented = false

    /// 하위 ViewModel(LoginViewModel, OnboardingViewModel 등) 생성 시 주입용으로 노출.
    /// AppContainer에서 1회 resolve한 인스턴스를 재사용한다.
    let authService: AuthServiceProtocol
    let socialLoginService: SocialLoginServiceProtocol
    let locationService: LocationServiceProtocol
    let onboardingCompletionStore: OnboardingCompletionStore
    private let newFeatureGuideStore: NewFeatureGuideStore

    private var didHandleLocationPermission = false
    private var didEvaluateV2UpdateGuide = false

    init(
        authService: AuthServiceProtocol,
        socialLoginService: SocialLoginServiceProtocol,
        locationService: LocationServiceProtocol,
        onboardingCompletionStore: OnboardingCompletionStore,
        newFeatureGuideStore: NewFeatureGuideStore
    ) {
        self.authService = authService
        self.socialLoginService = socialLoginService
        self.locationService = locationService
        self.onboardingCompletionStore = onboardingCompletionStore
        self.newFeatureGuideStore = newFeatureGuideStore
    }

    func bootstrap() async {
        guard onboardingCompletionStore.hasSeenOnboarding() else {
            routeState = .onboarding
            return
        }
        let state = await authService.currentAuthState()
        let nextRouteState = state.toRoute()
        if nextRouteState == .signedIn {
            await newFeatureGuideStore.refreshFeatureConfig()
            routeState = nextRouteState
            presentV2UpdateGuideIfNeeded()
        } else {
            routeState = nextRouteState
        }
    }

    func didCompleteOnboarding() {
        Task { @MainActor in
            let state = await authService.currentAuthState()
            let nextRouteState = state.toRoute()
            if nextRouteState == .signedIn {
                await newFeatureGuideStore.refreshFeatureConfig()
                routeState = nextRouteState
                presentV2UpdateGuideIfNeeded()
            } else {
                routeState = nextRouteState
            }
        }
    }

    func didCompleteSignIn() {
        routeState = .signedIn
        Task {
            await newFeatureGuideStore.refreshFeatureConfig()
            presentV2UpdateGuideIfNeeded()
        }
    }

    func didSignOut() {
        routeState = .signedOut
        didEvaluateV2UpdateGuide = false
        isV2UpdateGuidePresented = false
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

    func presentV2UpdateGuideIfNeeded(now: Date = Date()) {
        guard routeState == .signedIn, !didEvaluateV2UpdateGuide else { return }
        didEvaluateV2UpdateGuide = true
        isV2UpdateGuidePresented = newFeatureGuideStore.shouldShowV2UpdateModal(now: now)
    }

    func didConfirmV2UpdateGuide() {
        newFeatureGuideStore.markV2UpdateModalSeen()
        isV2UpdateGuidePresented = false
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
