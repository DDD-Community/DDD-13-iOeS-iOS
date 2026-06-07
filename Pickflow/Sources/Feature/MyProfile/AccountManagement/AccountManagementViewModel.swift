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

    /// 닉네임 최대 글자 수. 입력 단계에서 이 길이를 초과하지 못하도록 막는다.
    static let nicknameMaxLength = 12

    /// 저장 가능한(완성형) 닉네임 규칙: 한글(가–힣)·영문·숫자 2~12자.
    private static let validNicknameRegex = "^[가-힣a-zA-Z0-9]{2,\(nicknameMaxLength)}$"
    /// 허용 문자 집합. 위반 시 에러 문구를 노출한다. (조합 중 한글 자모는 허용해 깜빡임 방지)
    private static let allowedNicknameCharsRegex = "^[가-힣ㄱ-ㅎㅏ-ㅣa-zA-Z0-9]+$"

    private var trimmedNickname: String {
        nicknameDraft.trimmingCharacters(in: .whitespaces)
    }

    /// 변경된 닉네임이 저장 가능한 유효 닉네임인지. (변경하지 않았으면 유효로 간주)
    var isNicknameValid: Bool {
        let trimmed = trimmedNickname
        if trimmed == user?.nickname { return true }
        return trimmed.range(of: Self.validNicknameRegex, options: .regularExpression) != nil
    }

    /// 입력 중 노출할 검증 에러 문구. 없으면 nil.
    /// 비어있음·2자 미만은 에러 없이 저장만 비활성화한다.
    var nicknameValidationError: String? {
        let trimmed = trimmedNickname
        if trimmed == user?.nickname { return nil }
        if trimmed.isEmpty { return nil }
        if trimmed.range(of: Self.allowedNicknameCharsRegex, options: .regularExpression) == nil {
            return "닉네임은 한글, 영문, 숫자만 사용할 수 있어요."
        }
        return nil
    }

    var isSaveEnabled: Bool {
        guard let user else { return false }
        guard isNicknameValid else { return false }
        let nicknameChanged = trimmedNickname != user.nickname
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
