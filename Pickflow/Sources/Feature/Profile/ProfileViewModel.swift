import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let userService: UserServiceProtocol

    init(userService: UserServiceProtocol) {
        self.userService = userService
    }

    func fetchProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            user = try await userService.fetchCurrentUser()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
