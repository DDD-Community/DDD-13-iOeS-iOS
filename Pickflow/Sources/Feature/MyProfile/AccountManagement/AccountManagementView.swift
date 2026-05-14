import SwiftUI

struct AccountManagementView: View {
    @StateObject var viewModel: AccountManagementViewModel
    @Environment(\.dismiss) private var dismiss

    var onLoggedOut: () -> Void = {}

    @State private var isShowingWithdrawal = false

    var body: some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()

            Group {
                if let error = viewModel.loadError {
                    errorBody(message: error)
                } else {
                    mainBody
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
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.gray0)
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("계정 관리")
                    .pretendard(.heading(.small))
                    .foregroundStyle(.gray0)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.saveProfile() }
                } label: {
                    Text("저장")
                        .pretendard(.body(.medium(.bold)))
                        .foregroundStyle(
                            viewModel.isSaveEnabled ? UIAsset.Colors.sunsetOrange.color : UIAsset.Colors.gray50.color
                        )
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.isSaveEnabled)
            }
        }
        .task {
            await viewModel.onAppear()
        }
        .onChange(of: viewModel.logoutState) { _, newState in
            if case .done = newState {
                onLoggedOut()
                dismiss()
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

    // MARK: - Main Body

    private var mainBody: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                profileImageSection

                nicknameSection

                socialSection

                Divider()
                    .background(.gray80)

                accountActionsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Profile Image

    private var profileImageSection: some View {
        ZStack(alignment: .bottomTrailing) {
            profileImageView
                .frame(width: 96, height: 96)

            Circle()
                .fill(.gray80)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "camera.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.gray0)
                )
                .offset(x: 2, y: 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("프로필 사진 변경")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var profileImageView: some View {
        if let imageURL = viewModel.user?.profileImageURL {
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
                    .foregroundStyle(.gray20)

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.sunsetOrange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.gray80)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var socialProviderLabel: String {
        switch viewModel.user?.linkedSocialProvider {
        case .kakao: return "카카오로 로그인됨"
        case .apple: return "Apple로 로그인됨"
        case .none: return "—"
        }
    }

    // MARK: - Account Actions

    private var accountActionsSection: some View {
        VStack(spacing: 0) {
            Button {
                viewModel.requestLogout()
            } label: {
                Text("로그아웃")
                    .pretendard(.body(.medium()))
                    .foregroundStyle(.gray40)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.plain)

            Button {
                isShowingWithdrawal = true
            } label: {
                Text("회원탈퇴")
                    .pretendard(.body(.medium()))
                    .foregroundStyle(Color.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
