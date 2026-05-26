import SwiftUI

struct SpotDetailView: View {
    @StateObject var viewModel: SpotDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isReportSheetPresented = false
    @State private var isLoginViewPresented = false
    @State private var isOpenSpotSheetPresented = false

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
            if viewModel.previewState == .idle {
                await viewModel.onAppear()
            }
            viewModel.loadDetailIfNeeded()
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
            if viewModel.isLoginRequired {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.isLoginRequired = false
                            }
                        }
                    LoginPromptPopup(
                        onCancel: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.isLoginRequired = false
                            }
                        },
                        onLogin: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.isLoginRequired = false
                            }
                            isLoginViewPresented = true
                        }
                    )
                    .padding(.horizontal, 32)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: viewModel.isLoginRequired)
            }
        }
        .fullScreenCover(isPresented: $isLoginViewPresented) {
            LoginView(
                viewModel: LoginViewModel(socialLoginService: getSocialLoginService()),
                onSignInSucceeded: { isLoginViewPresented = false }
            )
        }
        .sheet(isPresented: $isOpenSpotSheetPresented) {
            MySpotComingSoonSheet(
                onCancel: { isOpenSpotSheetPresented = false },
                onNotify: {
                    isOpenSpotSheetPresented = false
                    viewModel.notifyUpdateRequested()
                }
            )
            .presentationDetents([.height(310)])
            .presentationDragIndicator(.visible)
            .presentationBackground(UIAsset.Colors.gray95.swiftUIColor)
        }
        .overlay {
            if let updateToast = viewModel.updateNotificationToast {
                Text(updateToast)
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(.gray90)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.gray0)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
                    .padding(.horizontal, 16)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.updateNotificationToast)
            }
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
        switch viewModel.detailState {
        case .idle, .loading:
            ProgressView()
                .tint(UIAsset.Colors.gray0.color)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .failed(message):
            ContentUnavailableView(
                "스팟 정보를 불러오지 못했어요.",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .loaded(spot):
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    SpotHeaderSection(spot: spot)
                    SpotPhotoSection(
                        imageURL: spot.imageUrl,
                        recordedTime: spot.recordedTime,
                        address: spot.address
                    )
                    SpotActionButtons(
                        isMine: spot.isMySpot,
                        isBookmarked: viewModel.isBookmarked,
                        onRoute: viewModel.openNaverMapsRoute,
                        onBookmark: { Task { await viewModel.toggleBookmark() } },
                        onOpenSpot: { isOpenSpotSheetPresented = true }
                    )
                    SpotRealTimeInfoSection(spot: spot)
                    ReportButton(action: { isReportSheetPresented = true })
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
    }
}

#if DEBUG
#Preview("SpotDetail - isMySpot true") {
    SpotDetailView(viewModel: SpotDetailDebugFactory.makeMyViewModel(spotId: 2))
}
#endif
