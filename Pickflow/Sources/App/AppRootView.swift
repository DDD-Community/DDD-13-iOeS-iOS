import SwiftUI
import CoreLocation

/// 앱 최상위 라우팅 컨테이너.
///
/// 인증 상태에 따라 `LoginView`와 홈 화면을 분기한다.
/// 초기 인증 상태 판정은 `AuthService.currentAuthState()`에 위임한다.
struct AppRootView: View {
    @StateObject private var viewModel: AppRootViewModel

    init(
        authService: AuthServiceProtocol,
        kakaoAuthProvider: KakaoAuthProviderProtocol,
        appleAuthProvider: AppleAuthProviderProtocol,
        tokenStore: TokenStoreProtocol,
        locationService: LocationServiceProtocol
    ) {
        _viewModel = StateObject(
            wrappedValue: AppRootViewModel(
                authService: authService,
                kakaoAuthProvider: kakaoAuthProvider,
                appleAuthProvider: appleAuthProvider,
                tokenStore: tokenStore,
                locationService: locationService
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
    let appleAuthProvider: AppleAuthProviderProtocol
    let tokenStore: TokenStoreProtocol
    let locationService: LocationServiceProtocol
    private var didHandleLocationPermission = false

    init(
        authService: AuthServiceProtocol,
        kakaoAuthProvider: KakaoAuthProviderProtocol,
        appleAuthProvider: AppleAuthProviderProtocol,
        tokenStore: TokenStoreProtocol,
        locationService: LocationServiceProtocol
    ) {
        self.authService = authService
        self.kakaoAuthProvider = kakaoAuthProvider
        self.appleAuthProvider = appleAuthProvider
        self.tokenStore = tokenStore
        self.locationService = locationService
    }

    func bootstrap() async {
        // FIXME(KAN-52 임시): 지도/리스트 화면 검증 위해 로그인 화면 우회. PR 머지 전 원복.
        authState = .signedIn
        return
        let state = await authService.currentAuthState()
        authState = state.toRoute()
    }

    func didCompleteSignIn() {
        authState = .signedIn
    }

    func prepareLocationPermissionIfNeeded() {
        guard authState == .signedIn, !didHandleLocationPermission else { return }
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
