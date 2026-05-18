import SwiftUI
import UIKit

/// 앱 런치 시 첫 뷰. 실질 라우팅은 `AppRootView`에서 수행한다.
struct ContentView: View {
    @State private var selectedTab: Tab
    @State private var explorePath = NavigationPath()
    @State private var savedPath = NavigationPath()
    @StateObject private var myProfileViewModel: MyProfileViewModel
    @StateObject private var archiveViewModel: ArchiveViewModel

    init(initialTab: Tab = .explore, myProfileViewModel: MyProfileViewModel? = nil) {
        _selectedTab = State(initialValue: initialTab)
        _myProfileViewModel = StateObject(wrappedValue: myProfileViewModel ?? MyProfileViewModel(
            userService: getUserService(),
            authService: getAuthService(),
            socialLoginService: getSocialLoginService()
        ))
        _archiveViewModel = StateObject(wrappedValue: ArchiveViewModel(
            archiveService: getArchiveService(),
            bookmarkService: getBookmarkService(),
            authService: getAuthService(),
            socialLoginService: getSocialLoginService()
        ))
    }

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
                    ArchiveView(
                        viewModel: archiveViewModel,
                        onExploreTap: { selectedTab = .explore }
                    )
                    .navigationBarHidden(true)
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
