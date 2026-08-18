import SwiftUI

struct MyProfileView: View {
    @StateObject var viewModel: MyProfileViewModel
    var onSignedOut: () -> Void = {}
    var onNavigateToSavedSpots: () -> Void = {}
    var onNavigateToRecordedSpots: () -> Void = {}

    // 앱 버전 연속 탭 → 패스코드 → API 환경 전환. 일반 유저가 우연히 닿지 않게 하는 용도다.
    @State private var appVersionTapCount = 0
    @State private var lastAppVersionTapAt: Date?
    @State private var isPasscodePromptPresented = false
    @State private var passcodeInput = ""
    @State private var isEnvironmentSwitchPresented = false

    var body: some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()

            switch viewModel.state {
            case .signedOut:
                MyProfileSignedOutContent(
                    onKakaoLoginTap: { Task { await viewModel.signInWithKakao() } },
                    onAppleLoginTap: { Task { await viewModel.signInWithApple() } }
                )

            case .loading:
                ProgressView()
                    .tint(UIAsset.Colors.gray0.color)

            case let .signedIn(user):
                MyProfileSignedInContent(
                    user: user,
                    cachedProfileImage: viewModel.cachedProfileImage,
                    onProfileImageTap: { viewModel.navigateToAccountManagement() },
                    onSavedSpotsTap: onNavigateToSavedSpots,
                    onRecordedSpotsTap: onNavigateToRecordedSpots,
                    supportEmail: viewModel.supportEmail,
                    onAccountManagementTap: { viewModel.navigateToAccountManagement() },
                    onNoticeTap: { viewModel.navigateToNotice() },
                    onTermsAndPolicyTap: { viewModel.navigateToTermsAndPolicy() },
                    environmentBadge: APIEnvironment.isOverridden ? APIEnvironment.current.rawValue : nil,
                    onAppVersionTap: registerAppVersionTap
                )

            case let .failed(message):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(.sunsetOrange)

                    Text(message)
                        .pretendard(.body(.medium()))
                        .foregroundStyle(.gray30)
                        .multilineTextAlignment(.center)

                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Text("다시 시도")
                            .pretendard(.body(.medium(.bold)))
                            .foregroundStyle(.gray0)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.sunsetOrange)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.onAppear()
        }
        .navigationDestination(isPresented: $viewModel.isNavigatingToAccountManagement) {
            AccountManagementView(
                viewModel: AccountManagementViewModel(
                    userService: viewModel.userService,
                    authService: viewModel.authService
                ),
                onLoggedOut: {
                    viewModel.handleSignedOut()
                    onSignedOut()
                },
                onSaved: {}
            )
        }
        .navigationDestination(isPresented: $viewModel.isNavigatingToNotice) {
            NoticeListView(viewModel: NoticeListViewModel(noticeService: getNoticeService()))
        }
        .navigationDestination(isPresented: $viewModel.isNavigatingToTermsAndPolicy) {
            TermsAndPolicyListView(documents: viewModel.termsPolicies)
        }
        .restoreAccountPrompt(
            info: viewModel.withdrawnAccountInfo,
            onCancel: { viewModel.cancelRestore() },
            onConfirm: { Task { await viewModel.confirmRestore() } }
        )
        .alert("코드를 입력해 주세요", isPresented: $isPasscodePromptPresented) {
            TextField("코드", text: $passcodeInput)
                .keyboardType(.numberPad)
            Button("취소", role: .cancel) { passcodeInput = "" }
            Button("확인") { submitPasscode() }
        }
        .navigationDestination(isPresented: $isEnvironmentSwitchPresented) {
            APIEnvironmentSwitchView(tokenStore: getTokenStore())
        }
    }

    /// 앱 버전 행을 짧은 간격으로 연속 탭하면 서버 전환 진입점이 열린다.
    /// 간격이 벌어지면 카운트를 리셋해, 스크롤 중 우연히 눌리는 경우를 걸러낸다.
    private func registerAppVersionTap() {
        let now = Date()
        let isContinuous = lastAppVersionTapAt.map {
            now.timeIntervalSince($0) <= APIEnvironmentUnlock.tapWindow
        } ?? false

        appVersionTapCount = isContinuous ? appVersionTapCount + 1 : 1
        lastAppVersionTapAt = now

        guard appVersionTapCount >= APIEnvironmentUnlock.requiredTapCount else { return }
        appVersionTapCount = 0
        lastAppVersionTapAt = nil
        passcodeInput = ""
        isPasscodePromptPresented = true
    }

    private func submitPasscode() {
        let entered = passcodeInput
        passcodeInput = ""
        guard entered == APIEnvironmentUnlock.passcode else { return }
        isEnvironmentSwitchPresented = true
    }
}
