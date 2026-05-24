import SwiftUI

struct SpotShellRootView: View {
    @ObservedObject var viewModel: SpotDetailViewModel
    var onDismiss: () -> Void = {}

    var body: some View {
        Group {
            switch viewModel.presentationPhase {
            case .sheetMedium:
                SheetChromeView {
                    sheetMediumContent
                }
                .transition(.opacity)
            case .sheetLarge, .fullCover:
                SpotDetailView(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.presentationPhase)
        .task {
            if viewModel.previewState == .idle {
                await viewModel.onAppear()
            }
        }
        .onAppear {
            if viewModel.previewState == .idle {
                Task { await viewModel.onAppear() }
            }
        }
    }

    @ViewBuilder
    private var sheetMediumContent: some View {
        switch viewModel.previewState {
        case .idle, .loading:
            loadingPlaceholder
        case let .failed(message):
            errorPlaceholder(message: message)
        case let .loaded(preview):
            SpotDetailSheetContentView(
                preview: preview,
                isBookmarked: viewModel.isBookmarked,
                onClose: onDismiss,
                onRoute: viewModel.openNaverMapsRoute,
                onBookmark: { Task { await viewModel.toggleBookmark() } }
            )
        }
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(UIAsset.Colors.gray0.swiftUIColor)
            Text("정보를 불러오는 중…")
                .pretendard(.body(.medium(.regular)))
                .foregroundStyle(.gray30)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 20)
    }

    private func errorPlaceholder(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(.gray30)
            Text("정보를 불러오지 못했어요")
                .pretendard(.body(.large(.bold)))
                .foregroundStyle(.gray5)
            Text(message)
                .pretendard(.body(.small(.regular)))
                .foregroundStyle(.gray30)
                .multilineTextAlignment(.center)
            Button("다시 시도") {
                Task { await viewModel.onAppear() }
            }
            .pretendard(.body(.medium(.bold)))
            .foregroundStyle(.sunsetOrange)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }
}

#if DEBUG
#Preview("Medium Sheet") {
    @Previewable @StateObject var viewModel = SpotDetailDebugFactory.makeViewModel(spotId: 1)

    ZStack(alignment: .bottom) {
        Color.black.opacity(0.4).ignoresSafeArea()
        SpotShellRootView(viewModel: viewModel)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.55)
    }
    .preferredColorScheme(.dark)
}

#Preview("Medium Sheet — 주소 펼침/저장됨") {
    ZStack(alignment: .bottom) {
        Color.black.opacity(0.4).ignoresSafeArea()
        SheetChromeView {
            SpotDetailSheetContentView(
                preview: SpotDetailDebugFixture.preview,
                isBookmarked: true,
                initialAddressExpanded: true
            )
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.55)
    }
    .preferredColorScheme(.dark)
}
#endif
