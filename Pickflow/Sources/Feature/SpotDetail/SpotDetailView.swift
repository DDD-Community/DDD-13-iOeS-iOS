import SwiftUI

struct SpotDetailView: View {
    @StateObject var viewModel: SpotDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()

            VStack(spacing: 0) {
                SpotDetailNavBar(
                    isBookmarked: viewModel.isBookmarked,
                    onBookmark: { Task { await viewModel.toggleBookmark() } },
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
        .overlay(alignment: .bottom) {
            if let toast = viewModel.toast {
                Text(toast)
                    .pretendard(.body(.small(.bold)))
                    .foregroundStyle(.gray0)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.gray80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.bottom, 24)
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
                VStack(alignment: .leading, spacing: 28) {
                    SpotHeaderSection(spot: spot)
                    SpotPhotoSection(imageURL: spot.primaryImage?.imageURL)
                    SpotActionButtons(
                        onRoute: viewModel.openNaverMapsRoute,
                        onShare: viewModel.share
                    )
                    SpotCommentSection(comment: spot.comment, recordedTime: spot.primaryImage?.recordedTime)
                    SpotWeatherSection(weather: spot.weather)
                    SpotTempCongestionSection(weather: spot.weather)
                    SunsetTimelineSection(sunsetTime: spot.weather.sunsetTime)
                    ReportButton(action: viewModel.reportInvalidInfo)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
    }
}
