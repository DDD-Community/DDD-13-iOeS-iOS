import SwiftUI

struct ProfileView: View {
    @StateObject var viewModel: ProfileViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let user = viewModel.user {
                VStack(spacing: 16) {
                    Text(user.name)
                        .font(.title)
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .task {
            await viewModel.fetchProfile()
        }
    }
}
