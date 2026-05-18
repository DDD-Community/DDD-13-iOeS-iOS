import SwiftUI
import UIKit

/// 리스트 화면. 헤더(PICKFLOW + 무드 capsule + 정렬 드롭다운)는 부모(HomeMapView)가 담당.
/// 본 뷰는 컨텐츠(상태에 따라 그리드/빈/실패/로딩/권한안내)만 렌더한다.
struct SpotListView: View {
    @StateObject var viewModel: SpotListViewModel
    var contentTopInset: CGFloat = 0
    @State private var isLoginViewPresented: Bool = false

    var body: some View {
        SpotListScreenContent(
            state: viewModel.state,
            isBookmarked: { viewModel.isBookmarked($0) },
            bookmarkCount: { _ in nil },  // FIXME(BE-API): 응답 추가 시 item.bookmarkCount 전달.
            onBookmarkTap: { id in Task { await viewModel.bookmarkTapped(id) } },
            onRetry: { Task { await viewModel.onAppear() } },
            onOpenSettings: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            },
            onAppearItem: { item in
                Task { await viewModel.loadNextPageIfNeeded(currentItem: item) }
            },
            contentTopInset: contentTopInset
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
        .fullScreenCover(isPresented: $isLoginViewPresented) {
            LoginView(
                viewModel: LoginViewModel(socialLoginService: getSocialLoginService()),
                onSignInSucceeded: { isLoginViewPresented = false }
            )
        }
    }
}

/// ViewModel 의존 없이 상태만으로 렌더 가능한 컨테이너. 스냅샷·Preview 에 사용.
struct SpotListScreenContent: View {
    let state: SpotListViewModel.LoadState
    let isBookmarked: (Int64) -> Bool
    let bookmarkCount: (Int64) -> Int?
    let onBookmarkTap: (Int64) -> Void
    let onRetry: () -> Void
    let onOpenSettings: () -> Void
    let onAppearItem: (SpotListItem) -> Void
    var contentTopInset: CGFloat = 0

    var body: some View {
        content
            .padding(.top, contentTopInset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(UIAsset.Colors.gray95.swiftUIColor)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .idle, .loading:
            SpotListLoadingView()
        case let .loaded(items, _):
            loadedGrid(items: items)
        case .empty:
            SpotListEmptyView()
        case let .failed(message):
            SpotListFailedView(message: message, onRetry: onRetry)
        case .locationUnauthorized:
            SpotListUnauthorizedLocationView(onOpenSettings: onOpenSettings)
        }
    }

    private func loadedGrid(items: [SpotListItem]) -> some View {
        ScrollView {
            MasonryTwoColumn(items: items, onAppearItem: onAppearItem) { item in
                SpotListCell(
                    item: item,
                    isBookmarked: isBookmarked(item.spotId),
                    bookmarkCount: bookmarkCount(item.spotId),
                    onBookmarkTap: { onBookmarkTap(item.spotId) }
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
}
