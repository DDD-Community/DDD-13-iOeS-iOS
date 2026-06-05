import SwiftUI

/// 공지사항 상세 화면. (Figma 1084:5720)
struct NoticeDetailView: View {
    @StateObject var viewModel: NoticeDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NoticeDetailContent(
            state: viewModel.state,
            onBack: { dismiss() },
            onRetry: { Task { await viewModel.retry() } }
        )
        .navigationBarHidden(true)
        .task { await viewModel.onAppear() }
    }
}

/// 상태 주입형 스테이트리스 컨텐츠 (스냅샷 대상).
struct NoticeDetailContent: View {
    let state: NoticeDetailViewModel.LoadState
    var onBack: () -> Void = {}
    var onRetry: () -> Void = {}

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
        case let .loaded(detail):
            loaded(detail)
        case let .failed(message):
            NoticeErrorView(message: message, onRetry: onRetry)
        }
    }

    private func loaded(_ detail: NoticeDetail) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(detail.title)
                        .pretendard(.body(.large()))
                        .foregroundStyle(.gray0)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(DateFormatter.noticeDisplayDate(from: detail.createdAt))
                        .pretendard(.body(.small()))
                        .foregroundStyle(.gray40)
                }
                .padding(.vertical, 12)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(UIAsset.Colors.gray80.color)
                        .frame(height: 1)
                }

                Text(detail.content)
                    .pretendard(.body(.medium()))
                    .foregroundStyle(.gray30)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(UIAsset.Colors.gray90.color)
    }
}
