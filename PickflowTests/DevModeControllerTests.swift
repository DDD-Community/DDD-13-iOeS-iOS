import XCTest
@testable import Pickflow

@MainActor
final class DevModeControllerTests: XCTestCase {

    /// `clock` 이 `@Sendable` 이라 테스트 인스턴스를 캡처할 수 없어 별도 박스를 둔다.
    private final class MutableClock: @unchecked Sendable {
        var now = Date(timeIntervalSince1970: 0)
    }

    private let clock = MutableClock()

    override func setUp() {
        super.setUp()
        APIEnvironment.clearOverride()
        UserDefaults.standard.removeObject(forKey: "devMode.showsEnvironmentBadge")
    }

    override func tearDown() {
        APIEnvironment.clearOverride()
        UserDefaults.standard.removeObject(forKey: "devMode.showsEnvironmentBadge")
        super.tearDown()
    }

    private func makeController() -> DevModeController {
        let clock = clock
        return DevModeController(clock: { clock.now })
    }

    // MARK: - 진입

    func test_연타횟수를채우기전에는_열리지않는다() {
        let controller = makeController()

        for _ in 0..<(APIEnvironmentUnlock.requiredTapCount - 1) {
            controller.registerMyTabTap()
        }

        XCTAssertFalse(controller.isPresented)
        XCTAssertFalse(controller.isPasscodePromptPresented)
    }

    /// 연타만으로는 열리지 않고 코드 입력을 거친다.
    func test_연타횟수를채우면_코드입력을묻는다() {
        let controller = makeController()

        for _ in 0..<APIEnvironmentUnlock.requiredTapCount {
            controller.registerMyTabTap()
        }

        XCTAssertTrue(controller.isPasscodePromptPresented)
        XCTAssertFalse(controller.isPresented)
    }

    func test_올바른코드를넣어야_열린다() {
        let controller = makeController()
        controller.requestEntry()

        controller.passcodeInput = "0000"
        controller.submitPasscode()
        XCTAssertFalse(controller.isPresented)

        controller.passcodeInput = APIEnvironmentUnlock.passcode
        controller.submitPasscode()
        XCTAssertTrue(controller.isPresented)
    }

    func test_코드입력후_입력값은남지않는다() {
        let controller = makeController()
        controller.requestEntry()

        controller.passcodeInput = APIEnvironmentUnlock.passcode
        controller.submitPasscode()

        XCTAssertTrue(controller.passcodeInput.isEmpty)
    }

    /// 평소 탭 이동으로 우연히 열리면 안 된다. 간격이 벌어지면 카운트가 리셋된다.
    func test_탭간격이벌어지면_카운트가리셋된다() {
        let controller = makeController()

        for _ in 0..<(APIEnvironmentUnlock.requiredTapCount - 1) {
            controller.registerMyTabTap()
        }
        clock.now = clock.now.addingTimeInterval(APIEnvironmentUnlock.tapWindow + 1)
        controller.registerMyTabTap()

        XCTAssertFalse(controller.isPresented)
    }

    // MARK: - 배지

    func test_기본값은_배지를띄우지않는다() {
        XCTAssertFalse(makeController().showsBadge)
    }

    func test_토글을켜면_배지가뜬다() {
        let controller = makeController()

        controller.isBadgePreferred = true

        XCTAssertTrue(controller.showsBadge)
    }

    /// 전환해둔 걸 모른 채 QA 하는 상황을 막는 안전장치.
    func test_기본환경이아니면_토글과무관하게_배지가뜬다() {
        APIEnvironment.setOverride(.prod)
        let controller = makeController()

        XCTAssertFalse(controller.isBadgePreferred)
        XCTAssertTrue(controller.showsBadge)
    }

    func test_배지선호값은_저장된다() {
        makeController().isBadgePreferred = true

        XCTAssertTrue(makeController().isBadgePreferred)
    }
}
