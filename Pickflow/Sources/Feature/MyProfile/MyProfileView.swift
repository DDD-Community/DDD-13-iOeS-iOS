import SwiftUI

struct MyProfileView: View {
    @StateObject var viewModel: MyProfileViewModel
    var onSignedOut: () -> Void = {}
    var onNavigateToSavedSpots: () -> Void = {}
    var onNavigateToRecordedSpots: () -> Void = {}

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
                    onTermsAndPolicyTap: { viewModel.navigateToTermsAndPolicy() }
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
        .apiEnvironmentDebugEntry()
    }
}

private extension View {
    /// Debug 빌드에서만 API 환경 전환 진입점을 붙인다. Release 빌드에서는 no-op.
    @ViewBuilder
    func apiEnvironmentDebugEntry() -> some View {
        #if DEBUG
        modifier(APIEnvironmentDebugEntry())
        #else
        self
        #endif
    }
}

#if DEBUG
private struct APIEnvironmentDebugEntry: ViewModifier {
    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresented = true
                    } label: {
                        Image(systemName: "ladybug")
                            .foregroundStyle(.gray30)
                    }
                    .accessibilityLabel("디버그 설정")
                }
            }
            .navigationDestination(isPresented: $isPresented) {
                APIEnvironmentDebugView(tokenStore: getTokenStore())
            }
    }
}
#endif
