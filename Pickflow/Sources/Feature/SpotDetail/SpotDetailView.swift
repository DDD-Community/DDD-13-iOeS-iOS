import SwiftUI

struct SpotDetailView: View {
    @StateObject var viewModel: SpotDetailViewModel
    var onShellDismiss: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var isReportSheetPresented = false
    @State private var isLoginViewPresented = false
    /// 반려 배너의 [수정 후 재신청] 로 여는 프리필 폼.
    @State private var resubmissionSpot: SpotDetail?

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
                if let onShellDismiss {
                    onShellDismiss()
                } else {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $isReportSheetPresented) {
            ReportSheet(
                onDismiss: { isReportSheetPresented = false },
                onSubmit: { content in
                    viewModel.reportInvalidInfo(content: content)
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
        .fullScreenCover(item: $resubmissionSpot) { spot in
            NavigationStack {
                SpotRegistrationView(
                    viewModel: makeResubmissionViewModel(for: spot),
                    onRegistered: { _ in resubmissionSpot = nil }
                )
            }
        }
        .onChange(of: resubmissionSpot) { previous, current in
            // 폼이 닫히면 상태가 바뀌었을 수 있으므로 상세를 다시 읽는다.
            if previous != nil, current == nil {
                Task { await viewModel.refreshAfterResubmission() }
            }
        }
        .fullScreenCover(isPresented: $isLoginViewPresented) {
            LoginView(
                viewModel: LoginViewModel(socialLoginService: getSocialLoginService()),
                onSignInSucceeded: { isLoginViewPresented = false },
                isClosable: true
            )
        }
        // 시스템 시트를 쓰지 않는다. iOS 26 은 시트를 화면에서 띄운 카드로 그려서
        // 하단·좌우에 여백이 생기고 네 모서리가 둥글어지는데, 시안은 화면 하단에 붙는
        // 형태다. 드래그도 detent 전환도 없는 확인용이라 직접 그리는 편이 단순하다.
        .overlay {
            if let sheet = viewModel.activeSheet {
                ZStack(alignment: .bottom) {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture { viewModel.dismissSheet() }

                    SpotPublicationSheetContent(
                        sheet: sheet,
                        onCancel: viewModel.dismissSheet,
                        onConfirm: { confirm(sheet) }
                    )
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: viewModel.activeSheet)
            }
        }
        .overlay {
            if viewModel.isOpenCompletePresented {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    SpotOpenCompletePopup(onConfirm: viewModel.acknowledgeOpenComplete)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: viewModel.isOpenCompletePresented)
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

    /// 공개 토글. OFF 는 즉시 비공개 전환이지만 ON 은 재검수를 거쳐야 하므로
    /// 바로 공개하지 않고 오픈 신청 시트를 띄운다.
    private var visibilityBinding: Binding<Bool> {
        Binding(
            get: { viewModel.publicationStatus == .published },
            set: { isOn in
                if isOn {
                    viewModel.presentSheet(.openRequest)
                } else {
                    Task { await viewModel.confirmCancelPublication() }
                }
            }
        )
    }

    private func makeResubmissionViewModel(for spot: SpotDetail) -> SpotRegistrationViewModel {
        let vm = SpotRegistrationViewModel(
            spotService: getSpotService(),
            mode: .resubmit(spotId: spot.spotId)
        )
        vm.prefill(from: spot)
        return vm
    }

    private func confirm(_ sheet: SpotPublicationSheet) {
        Task {
            switch sheet {
            case .openRequest: await viewModel.confirmOpenRequest()
            case .withdraw: await viewModel.confirmCancelPublication()
            case .delete: await viewModel.confirmDelete()
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
                    if spot.status == .rejected, spot.isMySpot, let rejection = spot.rejection {
                        SpotRejectionBanner(
                            rejection: rejection,
                            // TODO(PV-40): 반려 상태에서 호출할 API 가 서버에 없다. 정책 확정 후 연결.
                            onWithdraw: {},
                            onResubmit: { resubmissionSpot = spot }
                        )
                    }
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
                        onOpenSpot: { viewModel.presentSheet(.openRequest) },
                        publicationStatus: spot.isMySpot ? viewModel.publicationStatus : nil,
                        canLike: viewModel.canLike,
                        isLiked: viewModel.isLiked,
                        onWithdraw: { viewModel.presentSheet(.withdraw) },
                        onLike: { Task { await viewModel.toggleLike() } }
                    )
                    SpotRealTimeInfoSection(spot: spot)
                    ReportButton(action: {
                        if viewModel.isLoggedIn {
                            isReportSheetPresented = true
                        } else {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.isLoginRequired = true
                            }
                        }
                    })

                    if spot.isMySpot {
                        if viewModel.publicationStatus == .published {
                            SpotVisibilityToggle(isPublic: visibilityBinding)
                        }
                        SpotDeleteLink { viewModel.presentSheet(.delete) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
    }
}

