import SwiftUI
import UIKit

/// 앱 런치 시 첫 뷰. 실질 라우팅은 `AppRootView`에서 수행한다.
struct ContentView: View {
    @State private var selectedTab: Tab
    init(initialTab: Tab = .explore) {
        _selectedTab = State(initialValue: initialTab)
    }

    @State private var explorePath = NavigationPath()
    @State private var savedPath = NavigationPath()

    @StateObject private var myProfileViewModel = MyProfileViewModel(
        userService: getUserService(),
        authService: getAuthService(),
        socialLoginService: getSocialLoginService()
    )

    private var isTabBarVisible: Bool {
        switch selectedTab {
        case .explore: explorePath.isEmpty
        case .saved: savedPath.isEmpty
        case .my: !myProfileViewModel.isNavigatingToAccountManagement
        }
    }

    var body: some View {
        Group {
            switch selectedTab {
            case .explore:
                NavigationStack(path: $explorePath) {
                    ExploreHomeView()
                        .navigationDestination(for: DummyRoute.self) { route in
                            DetailDummyView(route: route)
                        }
                }
            case .saved:
                NavigationStack(path: $savedPath) {
                    SavedHomeView()
                        .navigationDestination(for: DummyRoute.self) { route in
                            DetailDummyView(route: route)
                        }
                }
            case .my:
                NavigationStack {
                    MyProfileView(viewModel: myProfileViewModel)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isTabBarVisible {
                CustomTabBar(selectedTab: $selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isTabBarVisible)
    }
}

#Preview {
    ContentView()
}

private enum ContentRoute: Hashable {
    case spotRegistration
}
