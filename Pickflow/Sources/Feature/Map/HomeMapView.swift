import SwiftUI

// 무드 필터 (노을/윤슬).
enum MoodFilter: String, CaseIterable, Sendable {
    case sunset = "노을"
    case reflection = "윤슬"

    var imageName: String {
        switch self {
        case .sunset:
            "icon_photo_category_sunset"
        case .reflection:
            "icon_photo_category_reflection"
        }

    }

    var spotTheme: SpotTheme {
        switch self {
        case .sunset: .sunset
        case .reflection: .reflection
        }
    }
    
    var apiCode: String {
        switch self {
        case .sunset: "SUNSET"
        case .reflection: "YUNSEUL"
        }
    }
}

struct HomeMapView: View {
    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter
    @State private var selectedMood: MoodFilter? = nil
    @State private var mapListMode: MapListMode = .map
    @Binding var isAddPlacePresented: Bool
    @Binding var isSpotDetailPresented: Bool
    @StateObject var clusteringViewModel: MapClusteringViewModel
    @State private var isSpotDetailSheetPresented = false
    @State private var selectedSpotVM: SpotDetailViewModel?
    @State private var listDetailVM: SpotDetailViewModel?
    // FIXME(§13a): selectedMood ↔ SpotListViewModel.selectedTheme 양방향 동기화 별도 PR
    @StateObject private var spotList = SpotListViewModel(
        spotListService: getSpotListService(),
        bookmarkService: getBookmarkService(),
        locationService: getLocationService(),
        tokenStore: getTokenStore()
    )
    @State private var topBarHeight: CGFloat = 0
    @State private var isSortExpanded: Bool = false
    @State private var cameraMoveRequest: CameraMoveRequest?
    @State private var userLocation: Coordinate?
    @State private var showAddPlaceLoginPrompt: Bool = false
    @State private var isAddPlaceLoginViewPresented: Bool = false
    @State private var showLocationPermissionPopup: Bool = false
    private let tokenStore = getTokenStore()
    private let locationService = getLocationService()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // MARK: - List overlay (지도 전체를 덮음, 헤더는 그 위에 오버레이)
                if mapListMode == .list {
                    // 헤더 bottom 으로부터 8pt 간격 — Padding.containerTop + topBarHeight + 8
                    SpotListView(
                        viewModel: spotList,
                        contentTopInset: Padding.containerTop + topBarHeight + 8,
                        onCellTap: { spotId in
                            listDetailVM = makeSpotDetailViewModel(spotId: spotId)
                            isSpotDetailPresented = true
                        }
                    )
                    .transition(.opacity)
                }

                // MARK: - Top overlay (List 위로 항상 떠 있는 무드 필터 헤더)
                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, Padding.containerHorizontal)
                        .padding(.top, Padding.containerTop)
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: TopBarHeightKey.self,
                                    value: proxy.size.height - Padding.containerTop
                                )
                            }
                        )
                        .overlay(alignment: .bottomTrailing) {
                            if mapListMode == .list, isSortExpanded {
                                SpotListSortDropdownOptions(current: spotList.sort) { picked in
                                    Task { await spotList.sortChanged(picked) }
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        isSortExpanded = false
                                    }
                                }
                                .padding(.trailing, Padding.containerHorizontal)
                                // PICKFLOW row 높이(~38pt) + 헤더 padding 합 → 정렬 버튼 아래로 떠오름
                                .offset(y: Padding.containerTop + 38 + 4)
                                .transition(.opacity)
                            }
                        }
                    Spacer()
                }
                .onPreferenceChange(TopBarHeightKey.self) { height in
                    topBarHeight = height
                }
                .onChange(of: mapListMode) { _, newMode in
                    if newMode == .map {
                        isSortExpanded = false
                    }
                }

                // MARK: - Bottom trailing overlay (Add Place 는 항상, 현재위치는 지도 모드 전용)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        trailingControls
                            .padding(.trailing, Padding.containerHorizontal)
                            .padding(.bottom, Padding.containerBottom + CustomTabBar.height)
                    }
                }

                // MARK: - Bottom overlay
                VStack {
                    Spacer()
                    MapListToggle(selectedMode: $mapListMode)
                        .padding(.bottom, Padding.containerBottom + CustomTabBar.height)
                }
            }
            .background {
                // NaverMapView 만 풀블리드로 그리고, 위 ZStack 본체는 safe area 안 layout 유지.
                // .background 의 자식은 부모 layout 에 영향 주지 않으므로 GeometryReader 불필요.
                NaverMapView(
                    spots: clusteringViewModel.state.spots,
                    mySpots: clusteringViewModel.mySpots,
                    selectedSpotId: clusteringViewModel.selectedSpotId,
                    cameraMoveRequest: cameraMoveRequest,
                    userLocation: userLocation,
                    onViewportChange: { viewport in
                        Task { await clusteringViewModel.viewportChanged(viewport) }
                    },
                    onSpotTap: { spotId in
                        clusteringViewModel.spotMarkerTapped(spotId)
                        if let coord = spotCoordinate(for: spotId) {
                            // 시트 medium(=화면 하단 55%) 에 가리지 않도록 마커를 상단 30% 위치로 정렬.
                            cameraMoveRequest = CameraMoveRequest(coordinate: coord, pivotY: 0.3)
                        }
                        presentSpotDetail(spotId: spotId)
                    },
                    onMapBackgroundTap: {
                        clusteringViewModel.mapBackgroundTapped()
                    }
                )
                .ignoresSafeArea()
            }
            .task {
                await refreshUserLocation()
            }
            .onChange(of: selectedMood) { _, mood in
                Task { await clusteringViewModel.themeChanged(mood?.spotTheme.apiCode) }
                // 무드 필터 지도-리스트 공유 (§13(a)): mood 변화 시 SpotListViewModel 도 갱신
                Task { await spotList.themeSynced(mood?.spotTheme) }
            }
            .navigationDestination(isPresented: $isAddPlacePresented) {
                SpotRegistrationAssembly.make { _ in
                    isAddPlacePresented = false
                    // 최초 스팟 등록 성공 직후 앱스토어 평점 요청 팝업 1회 발동.
                    getFirstSpotReviewRequester().spotRegistrationDidComplete()
                }
            }
            .fullScreenCover(
                isPresented: Binding(
                    get: { listDetailVM != nil },
                    set: { if !$0 { listDetailVM = nil; isSpotDetailPresented = false } }
                )
            ) {
                if let vm = listDetailVM {
                    SpotDetailView(viewModel: vm)
                }
            }
            .spotBottomSheet(isPresented: $isSpotDetailSheetPresented, viewModel: selectedSpotVM) {
                if let vm = selectedSpotVM {
                    SpotShellRootView(viewModel: vm) {
                        isSpotDetailSheetPresented = false
                    }
                }
            }
            .onChange(of: isSpotDetailSheetPresented) { _, isPresented in
                if !isPresented {
                    clusteringViewModel.mapBackgroundTapped()
                }
            }
            .onAppear {
                openPendingDeepLink()
            }
            .onChange(of: deepLinkRouter.pendingSpotId) { _, spotId in
                guard spotId != nil else { return }
                openPendingDeepLink()
            }
            .overlay {
                if showAddPlaceLoginPrompt {
                    ZStack {
                        Color.black.opacity(0.5).ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showAddPlaceLoginPrompt = false
                                }
                            }
                        LoginPromptPopup(
                            onCancel: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showAddPlaceLoginPrompt = false
                                }
                            },
                            onLogin: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showAddPlaceLoginPrompt = false
                                }
                                isAddPlaceLoginViewPresented = true
                            }
                        )
                        .padding(.horizontal, 32)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.25), value: showAddPlaceLoginPrompt)
                }
            }
            .fullScreenCover(isPresented: $isAddPlaceLoginViewPresented) {
                LoginView(
                    viewModel: LoginViewModel(socialLoginService: getSocialLoginService()),
                    onSignInSucceeded: { isAddPlaceLoginViewPresented = false },
                    isClosable: true
                )
            }
            .overlay {
                if showLocationPermissionPopup {
                    ZStack {
                        Color.black.opacity(0.5).ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showLocationPermissionPopup = false
                                }
                            }
                        LocationPermissionDeniedPopup(
                            onCancel: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showLocationPermissionPopup = false
                                }
                            },
                            onOpenSettings: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showLocationPermissionPopup = false
                                }
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        )
                        .padding(.horizontal, 32)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.25), value: showLocationPermissionPopup)
                }
            }
        }
    }

    // MARK: - Detail Presentation

    private func openPendingDeepLink() {
        guard let spotId = deepLinkRouter.pendingSpotId else { return }
        deepLinkRouter.pendingSpotId = nil
        listDetailVM = makeSpotDetailViewModel(spotId: spotId)
        isSpotDetailPresented = true
    }

    private func presentSpotDetail(spotId: Int64) {
        selectedSpotVM = makeSpotDetailViewModel(spotId: spotId)
        isSpotDetailSheetPresented = true
    }

    private func spotCoordinate(for spotId: Int64) -> Coordinate? {
        if let spot = clusteringViewModel.state.spots.first(where: { $0.id == spotId }) {
            return spot.coordinate
        }
        if let spot = clusteringViewModel.mySpots.first(where: { $0.id == spotId }) {
            return spot.coordinate
        }
        return nil
    }

    private func makeSpotDetailViewModel(spotId: Int64) -> SpotDetailViewModel {
        SpotDetailViewModel(
            spotId: spotId,
            spotService: getSpotService(),
            bookmarkService: getBookmarkService(),
            locationService: getLocationService(),
            externalAppLauncher: getExternalAppLauncher(),
            shareSheetPresenter: getShareSheetPresenter(),
            deviceIdProvider: {
                UIDevice.current.identifierForVendor?.uuidString ?? ""
            }
        )
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 14) {
          HStack(alignment: .center) {
              PickflowWorkMarkLogo()

                Spacer()

                if mapListMode == .list {
                    SpotListSortDropdownHeader(
                        sort: spotList.sort,
                        isExpanded: $isSortExpanded
                    )
                }
            }

            HStack(spacing: 8) {
                ForEach(MoodFilter.allCases, id: \.self) { mood in
                    moodCapsuleButton(mood)
                }
            }
        }
    }

    private func moodCapsuleButton(_ mood: MoodFilter) -> some View {
        Button {
            selectedMood = selectedMood == mood ? nil : mood
        } label: {
            HStack(spacing: 6) {
                
                Image(mood.imageName)
                    .renderingMode(.original)

                Text(mood.rawValue)
                    .pretendard(.body(.large(.bold)))
                    .padding(.vertical, 8)
                    .foregroundStyle(selectedMood == mood ? .white : .primary)
            }
            .padding(.horizontal, 14)
            .background(.gray95)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedMood == mood ? Color.orangeBorder : .clear, lineWidth: 1)
            )

        }
    }

    // MARK: - Trailing Controls

    private var trailingControls: some View {
        VStack(spacing: 12) {
            addPlaceButton
            if mapListMode == .map {
                currentPositionButton
            }
        }
        .padding(.horizontal, -20)
    }

    private var addPlaceButton: some View {
        Button {
            if (try? tokenStore.load()) != nil {
                isAddPlacePresented = true
            } else {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showAddPlaceLoginPrompt = true
                }
            }
        } label: {
            Image(.addLocation)
                .frame(width: Size.iconWidth, height: Size.iconHeight)
                .background(.gray95)
                .clipShape(Circle())
                .overlay(Circle().stroke(UIAsset.Colors.gray80.swiftUIColor, lineWidth: 1))
                .addTappableArea(.horizontal, 20)
        }
    }

    private var currentPositionButton: some View {
        Button {
            Task { await moveCameraToCurrentLocation() }
        } label: {
            Image(.myLocation)
                .frame(width: Size.iconWidth, height: Size.iconHeight)
                .background(.gray95)
                .clipShape(Circle())
                .overlay(Circle().stroke(UIAsset.Colors.gray80.swiftUIColor, lineWidth: 1))
                .addTappableArea(.horizontal, 20)
        }
    }

    private func moveCameraToCurrentLocation() async {
        switch locationService.authorizationStatus() {
        case .denied, .restricted:
            withAnimation(.easeInOut(duration: 0.25)) {
                showLocationPermissionPopup = true
            }
            return
        case .notDetermined:
            locationService.requestAuthorization()
        default:
            break
        }
        if let coordinate = try? await locationService.currentLocation() {
            userLocation = coordinate
            cameraMoveRequest = CameraMoveRequest(coordinate: coordinate, zoom: 15)
        }
    }

    private func refreshUserLocation() async {
        guard locationService.authorizationStatus() != .notDetermined else { return }
        if let coordinate = try? await locationService.currentLocation() {
            userLocation = coordinate
        }
    }

}

// MARK: - Colors

extension Color {
    fileprivate static let orangeBorder: Color = Color(
        red: 250 / 255, green: 97 / 255, blue: 51 / 255)
}

private struct TopBarHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

extension HomeMapView {
    fileprivate enum Size {
        static let iconWidth: CGFloat = 56
        static let iconHeight: CGFloat = 56
    }

    fileprivate enum Padding {
        static let containerTop: CGFloat = 12
        static let containerHorizontal: CGFloat = 16
        static let containerBottom: CGFloat = 24
    }
}

extension View {
    func addTappableArea(
        _ edges: Edge.Set = .all, _ length: CGFloat, shape: some Shape = Rectangle()
    ) -> some View {
        self
            .padding(edges, length)
            .contentShape(shape)
    }
}
#Preview {
    HomeMapView(
        isAddPlacePresented: .constant(false),
        isSpotDetailPresented: .constant(false),
        clusteringViewModel: MapClusteringViewModel(clusteringService: getClusteringService())
    )
    .environmentObject(DeepLinkRouter())
}
