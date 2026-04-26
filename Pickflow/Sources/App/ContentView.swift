import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .explore

    var body: some View {
        VStack {
            Group {
                switch selectedTab {
                case .explore:
                    ExploreHomeView()
                case .saved:
                    SavedHomeView()
                case .my:
                    MyHomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            CustomTabBar(selectedTab: $selectedTab)
        }
    }
}

#Preview {
    ContentView()
}
