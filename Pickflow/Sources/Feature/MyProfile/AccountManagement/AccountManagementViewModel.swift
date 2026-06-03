import Foundation

@MainActor
final class AccountManagementViewModel: ObservableObject {
    enum SaveState: Equatable {
        case idle
        case saving
        case saved
        case failed(String)
    }

    enum LogoutState: Equatable {
        case idle
        case confirming
        case processing
        case done
        case failed(String)
    }

    @Published private(set) var user: User?
    @Published private(set) var loadError: String?
    @Published var nicknameDraft: String = ""
    @Published var draftProfileImageData: Data?
    @Published private(set) var saveState: SaveState = .idle
    @Published private(set) var logoutState: LogoutState = .idle

    var isSaveEnabled: Bool {
        guard let user else { return false }
        let trimmed = nicknameDraft.trimmingCharacters(in: .whitespaces)
        let nicknameChanged = !trimmed.isEmpty && trimmed != user.nickname
        return nicknameChanged || draftProfileImageData != nil
    }

    func setDraftProfileImage(_ data: Data?) {
        draftProfileImageData = data
    }

    let userService: UserServiceProtocol
    let authService: AuthServiceProtocol

    init(userService: UserServiceProtocol, authService: AuthServiceProtocol) {
        self.userService = userService
        self.authService = authService
    }

    func onAppear() async {
        do {
            let loaded = try await userService.fetchCurrentUser()
            user = loaded
            nicknameDraft = loaded.nickname
        } catch let e as APIError {
            e.post()
        } catch {
            loadError = error.localizedDescription
        }
    }

    func saveProfile() async {
        let trimmed = nicknameDraft.trimmingCharacters(in: .whitespaces)
        guard isSaveEnabled else { return }
        saveState = .saving
        do {
            let nicknameToSend = trimmed != user?.nickname ? trimmed : nil
            let updated = try await userService.updateProfile(
                nickname: nicknameToSend,
                profileImageData: draftProfileImageData
            )
            user = updated
            nicknameDraft = updated.nickname
            draftProfileImageData = nil
            saveState = .saved
            NotificationCenter.default.post(name: .userProfileDidUpdate, object: nil)
        } catch let e as APIError {
            saveState = .idle
            e.post()
        } catch {
            saveState = .failed(error.localizedDescription)
        }
    }

    func requestLogout() {
        logoutState = .confirming
    }

    func cancelLogout() {
        logoutState = .idle
    }

    func confirmLogout() async {
        logoutState = .processing
        do {
            try await authService.signOut()
            logoutState = .done
            NotificationCenter.default.post(name: .userDidSignOut, object: nil)
        } catch let e as APIError {
            logoutState = .idle
            e.post()
        } catch {
            logoutState = .failed(error.localizedDescription)
        }
    }
}
