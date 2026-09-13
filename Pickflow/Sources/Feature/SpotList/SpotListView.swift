import SwiftUI

/// 리스트 화면. 헤더(PICKFLOW + 무드 capsule + 정렬 드롭다운)는 부모(HomeMapView)가 담당.
/// 본 뷰는 컨텐츠(상태에 따라 그리드/빈/실패/로딩/권한안내)만 렌더한다.
struct SpotListView: View {
    @StateObject var viewModel: SpotListViewModel
    var contentTopInset: CGFloat = 0
    var collapsibleHeaderHeight: CGFloat = 0
    var onHeaderCollapseChange: (CGFloat) -> Void = { _ in }
    var onCellTap: (Int64) -> Void = { _ in }
    @State private var isLoginViewPresented: Bool = false

    var body: some View {
        SpotListScreenContent(
            state: viewModel.state,
            isBookmarked: { viewModel.isBookmarked($0) },
            onBookmarkTap: { id in Task { await viewModel.bookmarkTapped(id) } },
            onCellTap: onCellTap,
            onRetry: { Task { await viewModel.onAppear() } },
            onAppearItem: { item in
                Task { await viewModel.loadNextPageIfNeeded(currentItem: item) }
            },
            contentTopInset: contentTopInset,
            collapsibleHeaderHeight: collapsibleHeaderHeight,
            onHeaderCollapseChange: onHeaderCollapseChange
        )
        .task { await viewModel.onAppear() }
        .overlay {
            if viewModel.showLoginPrompt {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.showLoginPrompt = false
                            }
                        }
                    LoginPromptPopup(
                        onCancel: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.showLoginPrompt = false
                            }
                        },
                        onLogin: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.showLoginPrompt = false
                            }
                            isLoginViewPresented = true
                        }
                    )
                    .padding(.horizontal, 32)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: viewModel.showLoginPrompt)
            }
        }
        .overlay {
            if viewModel.showLocationPermissionPrompt {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.showLocationPermissionPrompt = false
                            }
                        }
                    LocationPermissionDeniedPopup(
                        onCancel: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.showLocationPermissionPrompt = false
                            }
                        },
                        onOpenSettings: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.showLocationPermissionPrompt = false
                            }
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    )
                    .padding(.horizontal, 32)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: viewModel.showLocationPermissionPrompt)
            }
        }
        .fullScreenCover(isPresented: $isLoginViewPresented) {
            LoginView(
                viewModel: LoginViewModel(socialLoginService: getSocialLoginService()),
                onSignInSucceeded: { isLoginViewPresented = false },
                isClosable: true
            )
        }
    }
}

/// ViewModel 의존 없이 상태만으로 렌더 가능한 컨테이너. 스냅샷·Preview 에 사용.
struct SpotListScreenContent: View {
    let state: SpotListViewModel.LoadState
    let isBookmarked: (Int64) -> Bool
    let onBookmarkTap: (Int64) -> Void
    var onCellTap: (Int64) -> Void = { _ in }
    let onRetry: () -> Void
    let onAppearItem: (SpotListItem) -> Void
    var contentTopInset: CGFloat = 0
    /// 스크롤로 위로 밀어 올릴 수 있는 헤더 높이(탐색 탭의 로고+지역 영역).
    var collapsibleHeaderHeight: CGFloat = 0
    var onHeaderCollapseChange: (CGFloat) -> Void = { _ in }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(UIAsset.Colors.gray95.swiftUIColor)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .idle, .loading:
            SpotListLoadingView()
                .padding(.top, contentTopInset)
        case let .loaded(items, _):
            loadedGrid(items: items)
        case .empty:
            SpotListEmptyView()
                .padding(.top, contentTopInset)
        case let .failed(message):
            SpotListFailedView(message: message, onRetry: onRetry)
                .padding(.top, contentTopInset)
        }
    }

    private func loadedGrid(items: [SpotListItem]) -> some View {
        ScrollView {
            MasonryTwoColumn(items: items, onAppearItem: onAppearItem) { item in
                SpotListCell(
                    item: item,
                    isBookmarked: isBookmarked(item.spotId),
                    likeCount: item.likeCount,
                    onBookmarkTap: { onBookmarkTap(item.spotId) },
                    onCellTap: { onCellTap(item.spotId) }
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        // 카드가 헤더 뒤로 지나가며 스크롤되도록, 스크롤뷰는 화면 상단부터 두고 inset 은 컨텐츠 여백으로 준다.
        .contentMargins(.top, contentTopInset)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            Self.headerCollapse(
                scrollOffset: geometry.contentOffset.y + geometry.contentInsets.top,
                collapsibleHeight: collapsibleHeaderHeight
            )
        } action: { _, collapse in
            onHeaderCollapseChange(collapse)
        }
    }

    /// 스크롤 오프셋(맨 위 0, 아래로 스크롤할수록 +)을 헤더가 위로 밀려 올라갈 높이로 바꾼다.
    /// 당겨서 튕기는 음수 구간은 0, 접히는 영역 높이를 넘으면 그 높이에서 멈춘다.
    static func headerCollapse(scrollOffset: CGFloat, collapsibleHeight: CGFloat) -> CGFloat {
        min(max(scrollOffset, 0), collapsibleHeight)
    }
}
