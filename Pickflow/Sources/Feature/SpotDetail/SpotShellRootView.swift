import SwiftUI

struct SpotShellRootView: View {
    @ObservedObject var viewModel: SpotDetailViewModel
    var onDismiss: () -> Void = {}

    var body: some View {
        Group {
            switch viewModel.presentationPhase {
            case .sheetMedium:
                if case let .loaded(spot) = viewModel.state {
                    SheetChromeView {
                        SpotDetailSheetContentView(
                            spot: spot,
                            isBookmarked: viewModel.isBookmarked,
                            onClose: onDismiss,
                            onRoute: viewModel.openNaverMapsRoute,
                            onBookmark: { Task { await viewModel.toggleBookmark() } }
                        )
                    }
                    .transition(.opacity)
                } else {
                    SheetChromeView { EmptyView() }
                }
            case .sheetLarge, .fullCover:
                SpotDetailView(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.presentationPhase)
        .task {
            if viewModel.state == .idle {
                await viewModel.onAppear()
            }
        }
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
    @Previewable @StateObject var viewModel = SpotDetailDebugFactory.makeViewModel(spotId: 1)

    ZStack(alignment: .bottom) {
        Color.black.opacity(0.4).ignoresSafeArea()
        SheetChromeView {
            SpotDetailSheetContentView(
                spot: SpotDetailDebugFixture.spot,
                isBookmarked: true,
                initialAddressExpanded: true
            )
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.55)
    }
    .preferredColorScheme(.dark)
}
#endif
