import SwiftUI

struct ArchiveView: View {
    @StateObject var viewModel: ArchiveViewModel
    var onExploreTap: () -> Void = {}

    var body: some View {
        ZStack {
            UIAsset.Colors.gray95.swiftUIColor.ignoresSafeArea()
            mainBody
        }
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
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                ArchiveHeaderView(thumbnailURL: firstThumbnailURL)

                Section {
                    tabContent
                        .frame(minHeight: 300, alignment: .top)
                } header: {
                    ArchiveTabBar(
                        selectedTab: viewModel.selectedTab,
                        onTabChange: { viewModel.tabChanged($0) }
                    )
                }
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
        case .savedSpots:
            savedSpotsContent
        case .mySpots:
            ArchiveMySpotPlaceholder()
        }
    }

    @ViewBuilder
    private var savedSpotsContent: some View {
        switch viewModel.state {
        case .loading:
            SpotListLoadingView()
                .padding(.top, 16)
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
            SpotListFailedView(message: message) {
                Task { await viewModel.onAppear() }
            }
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
                    LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                        ArchiveHeaderView(thumbnailURL: firstThumbnailURL)

                        Section {
                            tabBody
                                .frame(minHeight: 300, alignment: .top)
                        } header: {
                            ArchiveTabBar(
                                selectedTab: selectedTab,
                                onTabChange: onTabChange
                            )
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
        case .savedSpots:
            savedBody
        case .mySpots:
            ArchiveMySpotPlaceholder()
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
