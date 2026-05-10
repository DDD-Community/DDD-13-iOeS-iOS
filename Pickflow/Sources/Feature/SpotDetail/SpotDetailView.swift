import SwiftUI

struct SpotDetailView: View {
    @StateObject var viewModel: SpotDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isReportSheetPresented = false

    var body: some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()

            VStack(spacing: 0) {
                SpotDetailNavBar(
                    onShare: viewModel.share,
                    onClose: viewModel.close
                )
                content
            }
        }
        .task {
            if viewModel.state == .idle {
                await viewModel.onAppear()
            }
        }
        .onChange(of: viewModel.dismissRequested) { _, isRequested in
            if isRequested {
                dismiss()
            }
        }
        .sheet(isPresented: $isReportSheetPresented) {
            ReportSheet(
                onDismiss: { isReportSheetPresented = false },
                onSubmit: { _ in
                    viewModel.reportInvalidInfo()
                    isReportSheetPresented = false
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(UIAsset.Colors.gray95.swiftUIColor)
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
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .tint(UIAsset.Colors.gray0.color)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .failed(message):
            VStack(spacing: 12) {
                Text("스팟 정보를 불러오지 못했어요.")
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(.gray0)
                Text(message)
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray50)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .loaded(spot):
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    SpotHeaderSection(spot: spot)
                    SpotPhotoSection(
                        imageURL: spot.primaryImage?.imageURL,
                        recordedTime: spot.primaryImage?.recordedTime,
                        address: spot.address
                    )
                    SpotActionButtons(
                        isMine: spot.isMine,
                        isBookmarked: viewModel.isBookmarked,
                        onRoute: viewModel.openNaverMapsRoute,
                        onBookmark: { Task { await viewModel.toggleBookmark() } },
                        onOpenSpot: viewModel.openSpot
                    )
                    SpotRealTimeInfoSection(
                        weather: spot.weather,
                        isMine: spot.isMine
                    )
                    ReportButton(action: { isReportSheetPresented = true })
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
    }
}
