import Foundation

/// Dev Mode 진입과 표시 상태를 한곳에서 관리한다.
///
/// 진입점은 **탭바의 마이 탭 연타**다. 예전에는 마이 화면의 앱 버전 행을 눌러야 했는데,
/// 그 화면은 로그인해야 보이는 영역이라 비로그인 상태에서는 환경을 바꿀 수 없었다.
/// 탭바는 로그인 여부와 무관하게 늘 떠 있으므로 QA 가 어느 상태에서든 진입할 수 있다.
@MainActor
final class DevModeController: ObservableObject {
    @Published var isPresented = false
    @Published var isPasscodePromptPresented = false
    @Published var passcodeInput = ""

    /// 환경 배지를 띄울지. 사용자가 끄면 꺼진 채로 유지된다.
    @Published var isBadgePreferred: Bool {
        didSet { UserDefaults.standard.set(isBadgePreferred, forKey: Self.badgeKey) }
    }

    private static let badgeKey = "devMode.showsEnvironmentBadge"

    private var tapCount = 0
    private var lastTapAt: Date?
    private let clock: @Sendable () -> Date

    init(clock: @escaping @Sendable () -> Date = Date.init) {
        self.clock = clock
        self.isBadgePreferred = UserDefaults.standard.bool(forKey: Self.badgeKey)
    }

    /// 기본 환경이 아니면 배지를 강제로 띄운다.
    /// 전환해둔 사실을 모른 채 "앱이 이상하다" 고 하는 상황을 막는 안전장치다.
    var showsBadge: Bool { isBadgePreferred || APIEnvironment.isOverridden }

    /// 마이 탭 버튼 탭. 짧은 간격으로 연달아 눌러야 카운트가 유지된다.
    /// 탭 전환 자체는 호출부에서 그대로 수행하므로 평소 사용에는 영향이 없다.
    func registerMyTabTap() {
        let now = clock()
        let isContinuous = lastTapAt.map {
            now.timeIntervalSince($0) <= APIEnvironmentUnlock.tapWindow
        } ?? false

        tapCount = isContinuous ? tapCount + 1 : 1
        lastTapAt = now

        guard tapCount >= APIEnvironmentUnlock.requiredTapCount else { return }
        resetTapCount()
        requestEntry()
    }

    /// 연타를 채웠거나 배지를 눌렀을 때. 어느 경로든 코드 입력을 거친다.
    /// 빌드 종류로 갈라두면 개발 중에 관문을 검증할 수 없어, Debug 에서도 똑같이 묻는다.
    func requestEntry() {
        passcodeInput = ""
        isPasscodePromptPresented = true
    }

    func submitPasscode() {
        let entered = passcodeInput
        passcodeInput = ""
        guard entered == APIEnvironmentUnlock.passcode else { return }
        isPresented = true
    }

    func cancelPasscode() {
        passcodeInput = ""
    }

    private func resetTapCount() {
        tapCount = 0
        lastTapAt = nil
    }
}
