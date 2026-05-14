import SwiftUI

struct MyProfileView: View {
    @StateObject var viewModel: MyProfileViewModel

    var body: some View {
        ZStack {
            Color("gray95").ignoresSafeArea()

            switch viewModel.state {
            case .signedOut:
                MyProfileSignedOutContent()

            case .loading:
                ProgressView()
                    .tint(Color("gray0"))

            case let .signedIn(user):
                MyProfileSignedInContent(
                    user: user,
                    onAccountManagementTap: { viewModel.navigateToAccountManagement() }
                )

            case let .failed(message):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(Color("sunsetOrange"))

                    Text(message)
                        .pretendard(.body(.medium()))
                        .foregroundStyle(Color("gray30"))
                        .multilineTextAlignment(.center)

                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Text("다시 시도")
                            .pretendard(.body(.medium(.bold)))
                            .foregroundStyle(Color("gray0"))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color("sunsetOrange"))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
            }
        }
        .task {
            await viewModel.onAppear()
        }
        .navigationDestination(isPresented: $viewModel.isNavigatingToAccountManagement) {
            AccountManagementView(
                viewModel: AccountManagementViewModel(
                    userService: viewModel.userService,
                    authService: viewModel.authService
                ),
                onLoggedOut: { viewModel.handleSignedOut() }
            )
        }
    }
}
