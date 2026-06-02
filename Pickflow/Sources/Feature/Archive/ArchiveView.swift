import SwiftUI
import UIKit

// MARK: - UIKit scroll offset reader (SwiftUI PreferenceKey doesn't update on scroll frames)

private final class ScrollOffsetCoordinator: NSObject, @unchecked Sendable {
    var onChange: (CGFloat) -> Void
    private weak var observedScrollView: UIScrollView?
    private var initialOffset: CGFloat?

    init(onChange: @escaping (CGFloat) -> Void) {
        self.onChange = onChange
    }

    func attach(to view: UIView) {
        guard observedScrollView == nil else { return }
        var cursor: UIView? = view.superview
        while let current = cursor {
            if let sv = current as? UIScrollView {
                observedScrollView = sv
                sv.addObserver(self, forKeyPath: "contentOffset",
                               options: [.initial, .new], context: nil)
                return
            }
            cursor = current.superview
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard keyPath == "contentOffset",
              let sv = object as? UIScrollView else { return }
        let y = sv.contentOffset.y
        if initialOffset == nil { initialOffset = y }
        let normalized = -(y - (initialOffset ?? y))
        DispatchQueue.main.async { [weak self] in self?.onChange(normalized) }
    }

    deinit {
        observedScrollView?.removeObserver(self, forKeyPath: "contentOffset")
    }
}

private struct ScrollOffsetReader: UIViewRepresentable {
    var onChange: (CGFloat) -> Void

    func makeCoordinator() -> ScrollOffsetCoordinator {
        ScrollOffsetCoordinator(onChange: onChange)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onChange = onChange
        DispatchQueue.main.async { context.coordinator.attach(to: uiView) }
    }
}

// MARK: - UIKit nav bar hider (removes nav bar AND its safe area contribution)

private struct NavBarHider: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }
    func updateUIViewController(_ vc: UIViewController, context: Context) {
        DispatchQueue.main.async {
            vc.navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }
}

// MARK: - ArchiveView

struct ArchiveView: View {
    @StateObject var viewModel: ArchiveViewModel
    var onExploreTap: () -> Void = {}

    // 0 = not scrolled, negative = scrolled up by N pts
    @State private var scrollOffset: CGFloat = 0
    // read once via GeometryReader; default covers most iPhones
    @State private var safeTop: CGFloat = 59
    @State private var showRegistration = false
    @State private var showRenameDialog = false
    @State private var showCoverPicker = false
    @State private var selectedSpotId: Int64?

    private var navTitleVisible: Bool { scrollOffset < -190 }

    private var headerTitleOpacity: CGFloat {
        max(0, min(1, (scrollOffset + 130) / 80))
    }

    // Photo extends into status bar by safeTop; photo bottom always = max(-196, scrollOffset) + 240
    private var headerStickyOffset: CGFloat {
        max(-196, scrollOffset) - safeTop
    }

    // ArchiveTabBar sticks directly below photo bottom (y=44 when photo is fully stuck)
    // No 44pt title-row gap — tabbar is adjacent to photo at all scroll positions
    private var tabBarStickyOffset: CGFloat {
        max(44, 240 + scrollOffset)
    }

    // ArchiveTabBar height: body.medium text + vertical padding 12*2 + indicator 2 ≈ 47pt
    private let tabBarHeight: CGFloat = 47

    // Large title tracks the photo bottom so it always sits at the lower-left of the photo
    private var largeTitleOffset: CGFloat {
        max(-196, scrollOffset) - safeTop
    }

    var body: some View {
        ZStack {
            UIAsset.Colors.gray95.swiftUIColor.ignoresSafeArea()
            mainBody
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.onAppear() }
        .alert("로그인 실패", isPresented: Binding(
            get: { viewModel.loginError != nil },
            set: { if !$0 { viewModel.clearLoginError() } }
        ), presenting: viewModel.loginError) { _ in
            Button("확인", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .overlay {
            if let toast = viewModel.toast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.gray95)
                    Text(toast)
                        .pretendard(.body(.medium(.bold)))
                        .foregroundStyle(.gray95)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.gray0)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.easeInOut(duration: 0.2), value: viewModel.toast)
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear.onAppear { safeTop = geo.safeAreaInsets.top }
            }
            .ignoresSafeArea()
        )
        .fullScreenCover(isPresented: Binding(
            get: { selectedSpotId != nil },
            set: { if !$0 { selectedSpotId = nil } }
        )) {
            if let spotId = selectedSpotId {
                SpotDetailView(viewModel: SpotDetailViewModel(
                    spotId: spotId,
                    spotService: getSpotService(),
                    bookmarkService: getBookmarkService(),
                    locationService: getLocationService(),
                    externalAppLauncher: getExternalAppLauncher(),
                    shareSheetPresenter: getShareSheetPresenter(),
                    deviceIdProvider: { UIDevice.current.identifierForVendor?.uuidString ?? "" }
                ))
            }
        }
        .navigationDestination(isPresented: $showRegistration) {
            SpotRegistrationAssembly.make { _ in showRegistration = false }
        }
        .fullScreenCover(isPresented: $showCoverPicker) {
            ArchiveCoverImagePickerView(
                archiveName: viewModel.archiveName,
                currentImageData: viewModel.coverImageData,
                onSelect: { data in Task { await viewModel.updateCoverImage(data) } }
            )
        }
        .overlay {
            if showRenameDialog {
                ArchiveRenameDialog(
                    isPresented: $showRenameDialog,
                    initialName: viewModel.archiveName,
                    onSave: { name in Task { await viewModel.renameArchive(name) } }
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: showRenameDialog)
            }
        }
    }

    @ViewBuilder
    private var mainBody: some View {
        switch viewModel.state {
        case .signedOut:
            ArchiveSignedOutContent(
                onKakaoTap: { Task { await viewModel.signInWithKakao() } },
                onAppleTap: { Task { await viewModel.signInWithApple() } }
            )
        default:
            scrollableContent
        }
    }

    private var scrollableContent: some View {
        ZStack(alignment: .top) {
            NavBarHider()
            // z=0 (back): cards scroll behind photo and tab bar
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // spacer = photo visible height below safe area + tab bar height
                    Color.clear.frame(height: 240 + tabBarHeight)
                    tabContent.frame(minHeight: 300, alignment: .top)
                }
                .background(ScrollOffsetReader { offset in scrollOffset = offset })
            }

            // z=1 (middle): photo in front of cards; top reaches screen top (behind status bar)
            ArchiveHeaderView(
                thumbnailURL: viewModel.archiveImageURL,
                coverImageData: viewModel.coverImageData,
                height: 240 + safeTop
            )
            .offset(y: headerStickyOffset)

            // z=2: ArchiveTabBar sticks directly below photo — no 44pt gap
            ArchiveTabBar(
                selectedTab: viewModel.selectedTab,
                onTabChange: { viewModel.tabChanged($0) }
            )
            .offset(y: tabBarStickyOffset)

            // z=3: nav bar row — title fades in on scroll, "..." button always visible
            HStack {
                Text(viewModel.archiveName)
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(.white)
                    .opacity(navTitleVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.25), value: navTitleVisible)
                Spacer()
                Menu {
                    Button("보관함 이름 변경") { showRenameDialog = true }
                    Button("커버 이미지 변경") { showCoverPicker = true }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(12)
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 20)
            .frame(height: 44)

            // z=4: large title — same frame/offset as photo so it always sits at photo bottom-left
            VStack(spacing: 0) {
                Spacer()
                Text(viewModel.archiveName)
                    .pretendard(.heading(.large))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            .frame(height: 240 + safeTop)
            .offset(y: largeTitleOffset)
            .opacity(headerTitleOpacity)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .savedSpots: savedSpotsContent
        case .mySpots: ArchiveMySpotPlaceholder(onRegisterTap: { showRegistration = true })
        }
    }

    @ViewBuilder
    private var savedSpotsContent: some View {
        switch viewModel.state {
        case .loading:
            SpotListLoadingView().padding(.top, 16)
        case let .loaded(items, _):
            MasonryTwoColumn(
                items: items,
                onAppearItem: { item in Task { await viewModel.loadNextPageIfNeeded(currentItem: item) } }
            ) { item in
                SpotListCell(
                    item: item,
                    isBookmarked: true,
                    bookmarkCount: nil,
                    onBookmarkTap: { Task { await viewModel.bookmarkTapped(item.spotId) } },
                    onCellTap: { selectedSpotId = item.spotId }
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        case .empty:
            ArchiveEmptyView(onExploreTap: onExploreTap)
        case let .failed(message):
            SpotListFailedView(message: message) { Task { await viewModel.onAppear() } }
        case .signedOut:
            EmptyView()
        }
    }
}

// MARK: - Snapshot/Preview support

struct ArchiveScreenContent: View {
    let state: ArchiveViewModel.LoadState
    let selectedTab: ArchiveTab
    var onExploreTap: () -> Void = {}
    var onTabChange: (ArchiveTab) -> Void = { _ in }

    var body: some View {
        ZStack {
            UIAsset.Colors.gray95.swiftUIColor.ignoresSafeArea()
            switch state {
            case .signedOut:
                ArchiveSignedOutContent()
            default:
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ArchiveHeaderView(thumbnailURL: firstThumbnailURL)
                        LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                            Section {
                                tabBody.frame(minHeight: 300, alignment: .top)
                            } header: {
                                ArchiveTabBar(selectedTab: selectedTab, onTabChange: onTabChange)
                            }
                        }
                    }
                }
            }
        }
    }

    private var firstThumbnailURL: URL? {
        guard case let .loaded(items, _) = state,
              let urlString = items.first?.thumbnailUrl else { return nil }
        return URL(string: urlString)
    }

    @ViewBuilder
    private var tabBody: some View {
        switch selectedTab {
        case .savedSpots: savedBody
        case .mySpots: ArchiveMySpotPlaceholder()
        }
    }

    @ViewBuilder
    private var savedBody: some View {
        switch state {
        case .loading:
            SpotListLoadingView().padding(.top, 16)
        case let .loaded(items, _):
            MasonryTwoColumn(items: items) { item in
                SpotListCell(item: item, isBookmarked: true, bookmarkCount: nil, onBookmarkTap: {})
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        case .empty:
            ArchiveEmptyView(onExploreTap: onExploreTap)
        case let .failed(message):
            SpotListFailedView(message: message, onRetry: {})
        case .signedOut:
            EmptyView()
        }
    }
}
