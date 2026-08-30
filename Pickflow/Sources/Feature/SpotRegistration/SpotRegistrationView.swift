import SwiftUI
import UIKit

struct SpotRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SpotRegistrationViewModel
    @State private var isDateSheetPresented = false
    @State private var isTimeSheetPresented = false
    @State private var isSpotSearchPresented = false
    private let onRegistered: @MainActor (SpotId) -> Void

    init(
        viewModel: SpotRegistrationViewModel,
        onRegistered: @escaping @MainActor (SpotId) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onRegistered = onRegistered
    }

    private var spotNameBinding: Binding<String> {
        Binding(
            get: { viewModel.spotName },
            set: { viewModel.setSpotName($0) }
        )
    }

    private var commentBinding: Binding<String> {
        Binding(
            get: { viewModel.comment },
            set: { viewModel.setComment($0) }
        )
    }

    private var themeBinding: Binding<SpotTheme?> {
        Binding(
            get: { viewModel.theme },
            set: { viewModel.theme = $0 }
        )
    }

    private var registerButtonColor: Color {
        viewModel.isRegisterEnabled ? .spotOrange : .spotDisabled
    }

    private var displayedDateText: String? {
        guard let capturedDate = viewModel.capturedDate else { return nil }
        return DateFormatter.spotCaptureDateDisplay.string(from: capturedDate)
    }

    private var displayedTimeText: String? {
        guard let capturedTime = viewModel.capturedTime else { return nil }
        return DateFormatter.spotCaptureTimeDisplay.string(from: capturedTime)
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    @ViewBuilder
    private var headerView: some View {
        HStack {
            Button {
                viewModel.backTapped()
            } label: {
                Group {
                    AssetImage(named: "icon_back_arrow", renderingMode: .template, size: 28) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 28, weight: .regular))
                            .frame(width: 28, height: 28)
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로가기")

            Spacer()

            Text("스팟 등록")
                .pretendard(.heading(.medium))
                .foregroundStyle(.white)

            Spacer()

            Button {
                Task {
                    await viewModel.submit()
                }
            } label: {
                Group {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 44, height: 44)
                    } else {
                        Text("등록")
                            .pretendard(.heading(.small))
                            .foregroundStyle(registerButtonColor)
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.isRegisterEnabled)
            .accessibilityLabel("등록")
            .accessibilityHint("입력한 내용으로 스팟을 등록합니다")
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(UIAsset.Colors.gray95.color)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SpotPhotoPickerCard(photoData: $viewModel.photoData, existingImageUrl: viewModel.existingImageUrl)

                if let selectedAddress = viewModel.selectedAddress,
                   let selectedAddressName = viewModel.selectedAddressName {
                    SpotAddressCard(
                        title: selectedAddressName,
                        address: selectedAddress.fullAddress,
                        distanceText: viewModel.selectedDistanceText
                    )
                }

                SpotSearchLocationButton {
                    isSpotSearchPresented = true
                }

                CountedTextField(
                    title: "스팟 이름",
                    placeholder: "이 장소를 무엇이라 부를까요?",
                    text: spotNameBinding,
                    count: viewModel.spotNameCount,
                    maxCount: 20
                )

                SpotThemeChipGroup(selectedCategory: themeBinding)

                CaptureDateTimeRow(
                    dateText: displayedDateText,
                    timeText: displayedTimeText,
                    isDateSheetPresented: $isDateSheetPresented,
                    isTimeSheetPresented: $isTimeSheetPresented
                )

                CountedTextEditor(
                    title: "한 줄 코멘트",
                    placeholder: "다른 사람을 위한 꿀팁이나\n촬영 후기를 남겨주세요.",
                    text: commentBinding,
                    count: viewModel.commentCount,
                    maxCount: 50
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .scrollDismissesKeyboard(.immediately)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboard()
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            headerView
        }
        .background(UIAsset.Colors.gray95.color.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isDateSheetPresented) {
            CaptureDatePickerSheet(initialDate: viewModel.capturedDate) { date in
                viewModel.setCapturedDate(date)
            }
        }
        .sheet(isPresented: $isTimeSheetPresented) {
            CaptureTimePickerSheet(
                selectedDate: viewModel.capturedDate,
                initialTime: viewModel.capturedTime
            ) { time in
                viewModel.setCapturedTime(time)
            }
        }
        .navigationDestination(isPresented: $isSpotSearchPresented) {
            SpotSearchView(
                viewModel: SpotSearchViewModel(
                    addressService: getAddressService(),
                    locationService: getLocationService()
                ),
                onSelectAddress: { address in
                    viewModel.applyAddressSelection(address)
                    isSpotSearchPresented = false
                }
            )
        }
        .alert(
            "등록 실패",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: viewModel.registeredSpotId) { _, newValue in
            guard let newValue else { return }
            onRegistered(newValue)
        }
        .onChange(of: viewModel.dismissRequested) { _, isRequested in
            if isRequested { dismiss() }
        }
        .onChange(of: viewModel.didResubmit) { _, didFinish in
            if didFinish { dismiss() }
        }
        .overlay {
            if viewModel.isExitConfirmPresented {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    SpotRegistrationExitConfirmPopup(
                        onContinue: viewModel.cancelExit,
                        onLeave: viewModel.confirmExit
                    )
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isExitConfirmPresented)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SpotRegistrationView(
            viewModel: SpotRegistrationViewModel(spotService: SpotRegistrationPreviewService()),
            onRegistered: { _ in }
        )
    }
}

private struct SpotRegistrationPreviewService: SpotServiceProtocol {
    func fetchSpotDetail(id: Int64, latitude: Double?, longitude: Double?) async throws -> SpotDetail {
        throw URLError(.notConnectedToInternet)
    }

    func fetchSpotPreview(id: Int64, latitude: Double?, longitude: Double?) async throws -> SpotPreviewResponse {
        throw URLError(.notConnectedToInternet)
    }

    func registerSpot(draft: SpotRegistrationDraft) async throws -> SpotId {
        SpotId(rawValue: "preview-spot-id")
    }

    func reportSpot(id: Int64, content: String) async throws {}

    func likeSpot(id: Int64) async throws -> SpotLikeResponse {
        throw URLError(.notConnectedToInternet)
    }

    func unlikeSpot(id: Int64) async throws -> SpotLikeResponse {
        throw URLError(.notConnectedToInternet)
    }
}
