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

    private var navTitleVisible: Bool { scrollOffset < -190 }

    // Large header title: fades out as scroll approaches -130
    private var headerTitleOpacity: CGFloat {
        max(0, min(1, (scrollOffset + 130) / 80))
    }

    // Header stops when its bottom edge aligns with the title row bottom (44pt from safe area top)
    // ArchiveHeaderView height 240pt − visible target 44pt = stop offset 196pt
    private var headerStickyOffset: CGFloat {
        max(-196, scrollOffset)
    }

    var body: some View {
        ZStack {
            UIAsset.Colors.gray95.swiftUIColor.ignoresSafeArea()
            mainBody
        }
        .background(NavBarHider())
        .task { await viewModel.onAppear() }
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
    }

    @ViewBuilder
    private var mainBody: some View {
        switch viewModel.state {
        case .signedOut:
            ArchiveSignedOutContent(
                isLoading: viewModel.isLoginLoading,
                onKakaoTap: { Task { await viewModel.signInWithKakao() } },
                onAppleTap: { Task { await viewModel.signInWithApple() } }
            )
        default:
            scrollableContent
        }
    }

    private var scrollableContent: some View {
        ZStack(alignment: .top) {
            // Photo header: scrolls with content then freezes when its bottom
            // reaches the title row bottom (44pt from safe area top).
            ArchiveHeaderView(
                thumbnailURL: firstThumbnailURL,
                titleOpacity: headerTitleOpacity
            )
            .offset(y: headerStickyOffset)
            .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 240)  // placeholder matching ArchiveHeaderView
                    LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                        Section {
                            tabContent.frame(minHeight: 300, alignment: .top)
                        } header: {
                            VStack(spacing: 0) {
                                HStack {
                                    Text("나의 보관함")
                                        .pretendard(.body(.large(.bold)))
                                        .foregroundStyle(.white)
                                        .opacity(navTitleVisible ? 1 : 0)
                                        .animation(.easeInOut(duration: 0.25), value: navTitleVisible)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .frame(height: 44)

                                ArchiveTabBar(
                                    selectedTab: viewModel.selectedTab,
                                    onTabChange: { viewModel.tabChanged($0) }
                                )
                            }
                        }
                    }
                }
                .background(ScrollOffsetReader { offset in scrollOffset = offset })
            }
        }
    }

    private var firstThumbnailURL: URL? {
        guard case let .loaded(items, _) = viewModel.state,
              let urlString = items.first?.thumbnailUrl else { return nil }
        return URL(string: urlString)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .savedSpots: savedSpotsContent
        case .mySpots: ArchiveMySpotPlaceholder()
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
                    onBookmarkTap: { Task { await viewModel.bookmarkTapped(item.spotId) } }
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
                ArchiveSignedOutContent(isLoading: false)
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
