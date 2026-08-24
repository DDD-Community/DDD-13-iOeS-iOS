import Combine
import SwiftUI
import UIKit

/// 앱 런치 시 첫 뷰. 실질 라우팅은 `AppRootView`에서 수행한다.
struct ContentView: View {
    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter
    @State private var selectedTab: Tab
    // 보관함 탭은 한 번 방문하면 뷰를 살려둔다(재생성 시 이미지 재로드·스크롤 리셋로 리프레시처럼 보임).
    @State private var hasVisitedSaved: Bool
    @State private var isExploreAddPlacePresented = false
    @State private var isExploreSpotDetailPresented = false
    @State private var savedPath = NavigationPath()
    // 회원탈퇴 완료 화면은 마이 탭의 하단 탭바가 보이는 상태로 노출되어야 한다.
    @State private var isWithdrawalComplete = false
    @StateObject private var clusteringViewModel: MapClusteringViewModel
    @StateObject private var myProfileViewModel: MyProfileViewModel
    @StateObject private var archiveViewModel: ArchiveViewModel
    // 탭바 위에 있으므로 로그인 여부와 무관하게 어느 화면에서든 진입할 수 있다.
    @StateObject private var devMode = DevModeController()

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
        _hasVisitedSaved = State(initialValue: initialTab == .saved)
        _myProfileViewModel = StateObject(wrappedValue: myProfileViewModel ?? MyProfileViewModel(
            userService: getUserService(),
            authService: getAuthService(),
            socialLoginService: getSocialLoginService(),
            appVersionService: getAppVersionService()
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
        case .my:
            // 계정 관리·공지사항·약관 등 마이 하위 상세 화면에서는 탭바를 숨긴다.
            // (탭바가 떠 있으면 상세 컨텐츠가 탭바 뒤로 가려 잘림)
            isWithdrawalComplete
                || (!myProfileViewModel.isNavigatingToAccountManagement
                    && !myProfileViewModel.isNavigatingToNotice
                    && !myProfileViewModel.isNavigatingToTermsAndPolicy)
        }
    }

    var body: some View {
        ZStack {
            switch selectedTab {
            case .explore:
                HomeMapView(
                    isAddPlacePresented: $isExploreAddPlacePresented,
                    isSpotDetailPresented: $isExploreSpotDetailPresented,
                    clusteringViewModel: clusteringViewModel
                )
            case .saved:
                // 실제 보관함 뷰는 아래 overlay 에서 항상 살아있다. 여기선 레이아웃 자리만.
                Color.clear
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

            // 보관함 탭: 최초 방문 시 생성 후 계속 살려둔다. 탭 전환마다 재생성되면
            // AsyncImage 썸네일/헤더 사진이 다시 로드되고 스크롤이 리셋돼 리프레시처럼 보인다.
            if hasVisitedSaved || selectedTab == .saved {
                NavigationStack(path: $savedPath) {
                    ArchiveView(
                        viewModel: archiveViewModel,
                        onExploreTap: { selectedTab = .explore }
                    )
                }
                .opacity(selectedTab == .saved ? 1 : 0)
                .allowsHitTesting(selectedTab == .saved)
                .zIndex(selectedTab == .saved ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottomLeading) {
            if devMode.showsBadge {
                DevModeBadge(environment: APIEnvironment.current) {
                    devMode.requestEntry()
                }
                .padding(.leading, 16)
                .padding(.bottom, 12)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isTabBarVisible {
                CustomTabBar(
                    selectedTab: $selectedTab,
                    onTabTapped: { tab in
                        guard tab == .my else { return }
                        devMode.registerMyTabTap()
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .alert("코드를 입력해 주세요", isPresented: $devMode.isPasscodePromptPresented) {
            TextField("코드", text: $devMode.passcodeInput)
                .keyboardType(.numberPad)
            Button("취소", role: .cancel) { devMode.cancelPasscode() }
            Button("확인") { devMode.submitPasscode() }
        }
        .fullScreenCover(isPresented: $devMode.isPresented) {
            DevModeView(
                controller: devMode,
                tokenStore: getTokenStore(),
                onClose: { devMode.isPresented = false }
            )
        }
        .animation(.easeInOut(duration: 0.25), value: isTabBarVisible)
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .saved { hasVisitedSaved = true }
        }
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
