import SnapshotTesting
import SwiftUI
import XCTest
@testable import Pickflow

@MainActor
final class LoginViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DesignSystemFontRegister.registerAllCustomFonts()
    }

    func test_login_root_idle_dark() {
        assertLoginSnapshot(
            named: "login-root-idle-dark",
            viewModel: makeViewModel()
        )
    }

    func test_login_header_idle_dark() {
        assertLoginSnapshot(
            named: "login-header-idle-dark",
            viewModel: makeViewModel()
        )
    }

    func test_login_header_closable_dark() {
        assertLoginSnapshot(
            named: "login-header-closable-dark",
            viewModel: makeViewModel(),
            isClosable: true
        )
    }

    func test_login_center_content_idle_dark() {
        assertLoginSnapshot(
            named: "login-center-content-idle-dark",
            viewModel: makeViewModel()
        )
    }

    func test_login_cta_idle_dark() {
        assertLoginSnapshot(
            named: "login-cta-idle-dark",
            viewModel: makeViewModel()
        )
    }

    func test_login_cta_kakao_loading_dark() {
        let viewModel = makeViewModel()
        viewModel.applySnapshotState(isLoading: true, activeLoginProvider: .kakao)

        assertLoginSnapshot(
            named: "login-cta-kakao-loading-dark",
            viewModel: viewModel
        )
    }

    func test_login_cta_apple_loading_dark() {
        let viewModel = makeViewModel()
        viewModel.applySnapshotState(isLoading: true, activeLoginProvider: .apple)

        assertLoginSnapshot(
            named: "login-cta-apple-loading-dark",
            viewModel: viewModel
        )
    }

    func test_login_alert_error_dark() {
        let viewModel = makeViewModel()
        viewModel.applySnapshotState(errorMessage: "로그인에 실패했어요")

        assertLoginSnapshot(
            named: "login-alert-error-dark",
            viewModel: viewModel
        )
    }

    func test_login_guest_requested_dark() {
        let viewModel = makeViewModel()
        viewModel.applySnapshotState(didRequestGuestEntry: true)

        assertLoginSnapshot(
            named: "login-guest-requested-dark",
            viewModel: viewModel
        )
    }

    func test_login_root_idle_light_forced_dark() {
        assertLoginSnapshot(
            named: "login-root-idle-light-forced-dark",
            viewModel: makeViewModel(),
            userInterfaceStyle: .light
        )
    }

    func test_login_root_accessibility_extra_large_dark() {
        assertLoginSnapshot(
            named: "login-root-accessibility-extra-large-dark",
            viewModel: makeViewModel(),
            dynamicTypeSize: .accessibility3
        )
    }

    func test_login_root_ipad_dark() {
        assertLoginSnapshot(
            named: "login-root-ipad-dark",
            viewModel: makeViewModel(),
            width: 834,
            height: 1194
        )
    }

    private func assertLoginSnapshot(
        named name: String,
        viewModel: LoginViewModel,
        width: CGFloat = 390,
        height: CGFloat = 844,
        userInterfaceStyle: UIUserInterfaceStyle = .dark,
        dynamicTypeSize: DynamicTypeSize = .large,
        isClosable: Bool = false,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        let view = LoginView(viewModel: viewModel, isClosable: isClosable)
            .environment(\.locale, Locale(identifier: "ko_KR"))
            .environment(\.dynamicTypeSize, dynamicTypeSize)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: width, height: height),
                traits: UITraitCollection(userInterfaceStyle: userInterfaceStyle)
            ),
            named: name,
            file: file,
            testName: testName,
            line: line
        )
    }

    private func makeViewModel() -> LoginViewModel {
        LoginViewModel(
            authService: MockAuthService(),
            kakaoAuthProvider: MockKakaoAuthProvider(),
            appleAuthProvider: MockAppleAuthProvider(),
            tokenStore: MockTokenStore()
        )
    }
}
