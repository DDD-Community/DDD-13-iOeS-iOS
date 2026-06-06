import SwiftUI

/// 공지사항 목록 화면. (Figma 1084:5706)
struct NoticeListView: View {
    @StateObject var viewModel: NoticeListViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedNotice: NoticeListItem?

    var body: some View {
        NoticeListContent(
            state: viewModel.state,
            isLoadingNextPage: viewModel.isLoadingNextPage,
            onBack: { dismiss() },
            onSelect: { selectedNotice = $0 },
            onRetry: { Task { await viewModel.retry() } },
            onItemAppear: { item in Task { await viewModel.loadNextPageIfNeeded(currentItem: item) } }
        )
        .navigationBarHidden(true)
        .task { await viewModel.onAppear() }
        .navigationDestination(
            isPresented: Binding(
                get: { selectedNotice != nil },
                set: { if !$0 { selectedNotice = nil } }
            )
        ) {
            if let selectedNotice {
                NoticeDetailView(
                    viewModel: NoticeDetailViewModel(
                        postId: selectedNotice.postId,
                        noticeService: getNoticeService()
                    )
                )
            }
        }
    }
}

/// 상태 주입형 스테이트리스 컨텐츠 (스냅샷 대상).
struct NoticeListContent: View {
    let state: NoticeListViewModel.LoadState
    var isLoadingNextPage: Bool = false
    var onBack: () -> Void = {}
    var onSelect: (NoticeListItem) -> Void = { _ in }
    var onRetry: () -> Void = {}
    var onItemAppear: (NoticeListItem) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            NoticeNavBar(onBack: onBack)
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(UIAsset.Colors.gray95.color)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .idle, .loading:
            NoticeLoadingView()
        case let .loaded(items):
            list(items)
        case .empty:
            NoticeEmptyView()
        case let .failed(message):
            NoticeErrorView(message: message, onRetry: onRetry)
        }
    }

    private func list(_ items: [NoticeListItem]) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(items) { item in
                    Button { onSelect(item) } label: {
                        NoticeRowView(item: item)
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(UIAsset.Colors.gray90.color)
                            .frame(height: 1)
                    }
                    .onAppear { onItemAppear(item) }
                }

                if isLoadingNextPage {
                    ProgressView()
                        .tint(UIAsset.Colors.gray0.color)
                        .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
