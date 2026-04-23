import SwiftUI
import UIKit

struct SpotRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SpotRegistrationViewModel
    @State private var isDateSheetPresented = false
    @State private var isTimeSheetPresented = false
    @State private var pushedSpotId: SpotId?

    init(viewModel: SpotRegistrationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
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

    private var categoryBinding: Binding<PhotoCategory?> {
        Binding(
            get: { viewModel.category },
            set: { viewModel.category = $0 }
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
                dismiss()
            } label: {
                Group {
                    if UIImage(named: "icon_back_arrow") != nil {
                        Image("icon_back_arrow")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                    } else {
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
        .background(Color.spotBackground)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SpotPhotoPickerCard(photoData: $viewModel.photoData)

                if let selectedAddress = viewModel.selectedAddress,
                   let selectedAddressName = viewModel.selectedAddressName {
                    SpotAddressCard(
                        title: selectedAddressName,
                        address: selectedAddress.fullAddress,
                        distanceText: viewModel.selectedDistanceText
                    )
                }

                SpotSearchLocationButton(
                    action: {
                        // TODO(KAN-XX): 주소 검색 화면 연결
                    },
                    debugLongPressAction: {
                        #if DEBUG
                        viewModel.applyMockAddressSelection()
                        #endif
                    }
                )

                CountedTextField(
                    title: "스팟 이름",
                    placeholder: "스팟 이름을 입력해 주세요.",
                    text: spotNameBinding,
                    count: viewModel.spotNameCount,
                    maxCount: 20
                )

                PhotoCategoryChipGroup(selectedCategory: categoryBinding)

                CaptureDateTimeRow(
                    dateText: displayedDateText,
                    timeText: displayedTimeText,
                    isDateSheetPresented: $isDateSheetPresented,
                    isTimeSheetPresented: $isTimeSheetPresented
                )

                CountedTextEditor(
                    title: "한 줄 코멘트",
                    placeholder: "스팟에 대한 한 줄 코멘트를 남겨주세요.",
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
        .background(Color.spotBackground.ignoresSafeArea())
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
        .navigationDestination(item: $pushedSpotId) { spotId in
            SpotDetailPlaceholderView(spotId: spotId)
        }
        .onChange(of: viewModel.registeredSpotId) { _, newValue in
            pushedSpotId = newValue
        }
    }
}

#Preview {
    NavigationStack {
        SpotRegistrationView(
            viewModel: SpotRegistrationViewModel(spotService: SpotRegistrationPreviewService())
        )
    }
}

private struct SpotRegistrationPreviewService: SpotServiceProtocol {
    func registerSpot(draft: SpotRegistrationDraft) async throws -> SpotId {
        SpotId(rawValue: "preview-spot-id")
    }
}
