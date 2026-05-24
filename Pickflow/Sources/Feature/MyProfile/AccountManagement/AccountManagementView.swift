import SwiftUI
import PhotosUI

struct AccountManagementView: View {
    @StateObject var viewModel: AccountManagementViewModel
    @Environment(\.dismiss) private var dismiss

    var onLoggedOut: () -> Void = {}
    var onSaved: () -> Void = {}

    @State private var isShowingWithdrawal = false
    @State private var photosPickerItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()

            VStack(spacing: 0) {
                customHeader

                Group {
                    if let error = viewModel.loadError {
                        errorBody(message: error)
                    } else {
                        mainBody
                    }
                }
            }

            if case .confirming = viewModel.logoutState {
                LogoutConfirmDialog(
                    onCancel: { viewModel.cancelLogout() },
                    onConfirm: { Task { await viewModel.confirmLogout() } }
                )
            }

            if case .processing = viewModel.logoutState {
                LogoutConfirmDialog(
                    onCancel: {},
                    onConfirm: {},
                    isLoading: true
                )
            }

            if case .saving = viewModel.saveState {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.4)
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.onAppear()
        }
        .onChange(of: viewModel.logoutState) { _, newState in
            if case .done = newState {
                onLoggedOut()
                dismiss()
            }
        }
        .onChange(of: viewModel.saveState) { _, newState in
            if case .saved = newState {
                onSaved()
                dismiss()
            }
        }
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    viewModel.setDraftProfileImage(data)
                }
            }
        }
        .navigationDestination(isPresented: $isShowingWithdrawal) {
            WithdrawalView(
                viewModel: WithdrawalViewModel(
                    userService: viewModel.userService,
                    authService: viewModel.authService
                ),
                onWithdrawn: {
                    onLoggedOut()
                    dismiss()
                }
            )
        }
    }

    // MARK: - Custom Header

    private var customHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.gray0)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("계정 관리")
                .pretendard(.heading(.small))
                .foregroundStyle(.gray0)

            Spacer()

            Button {
                Task { await viewModel.saveProfile() }
            } label: {
                Text("저장")
                    .pretendard(.body(.medium(.bold)))
                    .foregroundStyle(
                        viewModel.isSaveEnabled && viewModel.saveState != .saving
                            ? UIAsset.Colors.sunsetOrange.color
                            : UIAsset.Colors.gray50.color
                    )
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.isSaveEnabled || viewModel.saveState == .saving)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Main Body

    private var mainBody: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                profileImageSection

                nicknameSection

                socialSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            VStack(spacing: 0) {
                accountActionsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    // MARK: - Profile Image

    private var profileImageSection: some View {
        PhotosPicker(selection: $photosPickerItem, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                profileImageView
                    .frame(width: 96, height: 96)

                Circle()
                    .fill(.white)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.black)
                    )
                    .offset(x: 2, y: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("프로필 사진 변경")
    }

    @ViewBuilder
    private var profileImageView: some View {
        if let data = viewModel.draftProfileImageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipShape(Circle())
        } else if let urlString = viewModel.user?.profileImageUrl, let imageURL = URL(string: urlString) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                case .failure, .empty:
                    defaultProfileCircle
                @unknown default:
                    defaultProfileCircle
                }
            }
        } else {
            defaultProfileCircle
        }
    }

    private var defaultProfileCircle: some View {
        Circle()
            .fill(.gray80)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.gray50)
            )
    }

    // MARK: - Nickname Section

    private var nicknameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("닉네임")
                .pretendard(.label(.medium))
                .foregroundStyle(.gray40)

            TextField("닉네임을 입력하세요", text: $viewModel.nicknameDraft)
                .pretendard(.body(.large()))
                .foregroundStyle(.gray0)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.gray80)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    // MARK: - Social Section

    private var socialSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("연결된 소셜")
                .pretendard(.label(.medium))
                .foregroundStyle(.gray40)

            HStack {
                Text(socialProviderLabel)
                    .pretendard(.body(.medium()))
                    .foregroundStyle(.gray50)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.gray90)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var socialProviderLabel: String { "—" }

    // MARK: - Account Actions

    private var accountActionsSection: some View {
        VStack(spacing: 0) {
            Button {
                viewModel.requestLogout()
            } label: {
                Text("로그아웃")
                    .pretendard(.body(.medium()))
                    .foregroundStyle(.gray0)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.plain)

            Button {
                isShowingWithdrawal = true
            } label: {
                Text("회원탈퇴")
                    .pretendard(.body(.medium()))
                    .foregroundStyle(Color.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Error Body

    private func errorBody(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.sunsetOrange)

            Text(message)
                .pretendard(.body(.medium()))
                .foregroundStyle(.gray30)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }
}
