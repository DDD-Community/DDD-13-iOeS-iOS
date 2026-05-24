import SwiftUI

// 무드 필터 (노을/윤슬).
enum MoodFilter: String, CaseIterable, Sendable {
    case sunset = "노을"
    case ripple = "윤슬"

    var imageName: String {
        switch self {
        case .sunset:
            "sunset"
        case .ripple:
            "sparklingRipple"
        }

    }

    var spotTheme: SpotTheme {
        switch self {
        case .sunset: .sunset
        case .ripple: .reflection
        }
    }
}

struct HomeMapView: View {
    @State private var selectedMood: MoodFilter? = nil
    @State private var mapListMode: MapListMode = .map
    @Binding var isAddPlacePresented: Bool
    @Binding var isSpotDetailPresented: Bool
    @StateObject private var clustering = MapClusteringViewModel(clusteringService: getClusteringService())
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
                                .transition(.opacity.combined(with: .move(edge: .top)))
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

                // MARK: - Bottom trailing overlay (지도 모드에서만 표시)
                if mapListMode == .map {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            trailingControls
                                .padding(.trailing, Padding.containerHorizontal)
                                .padding(.bottom, Padding.containerBottom + CustomTabBar.height)
                        }
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
                    spots: clustering.state.spots,
                    mySpots: clustering.mySpots,
                    selectedSpotId: clustering.selectedSpotId,
                    onViewportChange: { viewport in
                        Task { await clustering.viewportChanged(viewport) }
                    },
                    onSpotTap: { spotId in
                        clustering.spotMarkerTapped(spotId)
                        presentSpotDetail(spotId: spotId)
                    },
                    onMapBackgroundTap: {
                        clustering.mapBackgroundTapped()
                    }
                )
                .ignoresSafeArea()
            }
            .onChange(of: selectedMood) { _, mood in
                Task { await clustering.themeChanged(mood?.spotTheme.apiCode) }
                // 무드 필터 지도-리스트 공유 (§13(a)): mood 변화 시 SpotListViewModel 도 갱신
                Task { await spotList.themeSynced(mood?.spotTheme) }
            }
            .navigationDestination(isPresented: $isAddPlacePresented) {
                SpotRegistrationAssembly.make { _ in
                    isAddPlacePresented = false
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
                    clustering.mapBackgroundTapped()
                }
            }
        }
    }

    // MARK: - Detail Presentation

    private func presentSpotDetail(spotId: Int64) {
        selectedSpotVM = makeSpotDetailViewModel(spotId: spotId)
        isSpotDetailSheetPresented = true
    }

    private func makeSpotDetailViewModel(spotId: Int64) -> SpotDetailViewModel {
        SpotDetailViewModel(
            spotId: spotId,
            spotService: getSpotService(),
            bookmarkService: getBookmarkService(),
            shareIntentService: getShareIntentService(),
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
              Image(.logo)
                    .padding(.leading, 16)
                    .padding(.top, 12)

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
            HStack(spacing: 4) {

                Image(mood.imageName)

                Text(mood.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.vertical, 6)
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
            // Add place button
            Button {
                isAddPlacePresented = true
            } label: {
                Image(.addLocation)
                    .frame(width: Size.iconWidth, height: Size.iconHeight)
                    .background(.gray95)
                    .clipShape(Circle())
                    .addTappableArea(.horizontal, 20)
            }

            // Current position button
            Button {
                // TODO: 현재 위치로 이동
            } label: {
                Image(.myLocation)
                    .frame(width: Size.iconWidth, height: Size.iconHeight)
                    .background(.gray95)
                    .clipShape(Circle())
                    .addTappableArea(.horizontal, 20)
            }
        }
        .padding(.horizontal, -20)
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
        static let containerTop: CGFloat = 16
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
    HomeMapView(isAddPlacePresented: .constant(false), isSpotDetailPresented: .constant(false))
}
