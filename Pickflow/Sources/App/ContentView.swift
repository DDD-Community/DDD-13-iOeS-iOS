import Combine
import SwiftUI
import UIKit

/// 앱 런치 시 첫 뷰. 실질 라우팅은 `AppRootView`에서 수행한다.
struct ContentView: View {
    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter
    @State private var selectedTab: Tab
    @State private var isExploreAddPlacePresented = false
    @State private var isExploreSpotDetailPresented = false
    @State private var savedPath = NavigationPath()
    // 회원탈퇴 완료 화면은 마이 탭의 하단 탭바가 보이는 상태로 노출되어야 한다.
    @State private var isWithdrawalComplete = false
    @StateObject private var clusteringViewModel: MapClusteringViewModel
    @StateObject private var myProfileViewModel: MyProfileViewModel
    @StateObject private var archiveViewModel: ArchiveViewModel

    var onSignedOut: () -> Void = {}

    init(
        initialTab: Tab = .explore,
        clusteringViewModel: MapClusteringViewModel? = nil,
        myProfileViewModel: MyProfileViewModel? = nil,
        archiveViewModel: ArchiveViewModel? = nil,
        onSignedOut: @escaping () -> Void = {}
    ) {
        self.onSignedOut = onSignedOut
        _selectedTab = State(initialValue: initialTab)
        _myProfileViewModel = StateObject(wrappedValue: myProfileViewModel ?? MyProfileViewModel(
            userService: getUserService(),
            authService: getAuthService(),
            socialLoginService: getSocialLoginService()
        ))
      
        _clusteringViewModel = StateObject(wrappedValue: clusteringViewModel ?? MapClusteringViewModel(
            clusteringService: getClusteringService())
        )
      
        _archiveViewModel = StateObject(wrappedValue: archiveViewModel ?? ArchiveViewModel(
            archiveService: getArchiveService(),
            bookmarkService: getBookmarkService(),
            authService: getAuthService(),
            socialLoginService: getSocialLoginService(),
            locationService: getLocationService()
        ))
    }

    private var isTabBarVisible: Bool {
        switch selectedTab {
        case .explore: !isExploreAddPlacePresented && !isExploreSpotDetailPresented
        case .saved: savedPath.isEmpty
        case .my: !myProfileViewModel.isNavigatingToAccountManagement || isWithdrawalComplete
        }
    }

    var body: some View {
        Group {
            switch selectedTab {
            case .explore:
                HomeMapView(
                    isAddPlacePresented: $isExploreAddPlacePresented,
                    isSpotDetailPresented: $isExploreSpotDetailPresented,
                    clusteringViewModel: clusteringViewModel
                )
            case .saved:
                NavigationStack(path: $savedPath) {
                    ArchiveView(
                        viewModel: archiveViewModel,
                        onExploreTap: { selectedTab = .explore }
                    )
                }
            case .my:
                NavigationStack {
                    MyProfileView(
                        viewModel: myProfileViewModel,
                        onSignedOut: onSignedOut,
                        onNavigateToSavedSpots: {
                            archiveViewModel.tabChanged(.savedSpots)
                            selectedTab = .saved
                        },
                        onNavigateToRecordedSpots: {
                            archiveViewModel.tabChanged(.mySpots)
                            selectedTab = .saved
                        }
                    )
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
        .onChange(of: deepLinkRouter.pendingSpotId) { _, spotId in
            guard spotId != nil else { return }
            selectedTab = .explore
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidWithdraw)) { _ in
            // 탈퇴 완료 화면(WithdrawalView .done)이 뜨는 동안 마이 탭 하단 탭바를 노출한다.
            isWithdrawalComplete = true
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DeepLinkRouter())
}

private enum ContentRoute: Hashable {
    case spotRegistration
}
