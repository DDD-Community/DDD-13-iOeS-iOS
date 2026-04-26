import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .explore
    @State private var explorePath = NavigationPath()
    @State private var savedPath = NavigationPath()
    @State private var myPath = NavigationPath()

    private var isTabBarVisible: Bool {
        switch selectedTab {
        case .explore: explorePath.isEmpty
        case .saved: savedPath.isEmpty
        case .my: myPath.isEmpty
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
                NavigationStack(path: $myPath) {
                    MyHomeView()
                        .navigationDestination(for: DummyRoute.self) { route in
                            DetailDummyView(route: route)
                        }
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
