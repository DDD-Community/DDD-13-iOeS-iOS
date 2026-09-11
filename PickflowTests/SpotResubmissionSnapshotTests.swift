import SnapshotTesting
import SwiftUI
import XCTest

@testable import Pickflow

/// PV-40 — 반려 스팟 재신청 폼. 케이스 정의는 docs/PV-40/ui-test-cases.md.
@MainActor
final class SpotResubmissionSnapshotTests: XCTestCase {

    private static let light = UITraitCollection(userInterfaceStyle: .light)
    private static let dark = UITraitCollection(userInterfaceStyle: .dark)
    private static let a11yDark = UITraitCollection(traitsFrom: [
        UITraitCollection(userInterfaceStyle: .dark),
        UITraitCollection(preferredContentSizeCategory: .accessibilityExtraLarge),
    ])

    private let rejected = SpotDetail.fixture(
        spotId: 7,
        isMySpot: true,
        theme: .reflection,
        imageUrl: "https://example.com/spot.jpg",
        comment: "노을빛에 반사된 윤슬이 가장 반짝여요.",
        status: .rejected
    )

    // MARK: - 프리필된 폼

    func test_resubmit_form_prefilled_light() {
        assert(form(), width: 393, height: 852, traits: Self.light)
    }

    func test_resubmit_form_prefilled_dark() {
        assert(form(), width: 393, height: 852, traits: Self.dark)
    }

    // MARK: - 이탈 확인 팝업

    func test_resubmit_exit_popup_light() {
        assert(popup, width: 390, height: 230, traits: Self.light)
    }

    func test_resubmit_exit_popup_dark() {
        assert(popup, width: 390, height: 230, traits: Self.dark)
    }

    func test_resubmit_exit_popup_a11y() {
        assert(popup, width: 390, height: 440, traits: Self.a11yDark)
    }

    // MARK: - Builders

    private func form() -> some View {
        let viewModel = SpotRegistrationViewModel(
            spotService: MockSpotService(),
            mySpotService: MockMySpotService(),
            mode: .resubmit(spotId: rejected.spotId)
        )
        viewModel.prefill(from: rejected)
        return SpotRegistrationView(viewModel: viewModel, onRegistered: { _ in })
    }

    private var popup: some View {
        SpotRegistrationExitConfirmPopup(onContinue: {}, onLeave: {})
    }

    private func assert(
        _ view: some View,
        width: CGFloat,
        height: CGFloat,
        traits: UITraitCollection,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let container = VStack(spacing: 0) { view }
            .frame(width: width, height: height)
            .background(UIAsset.Colors.gray95.swiftUIColor)
            .environment(\.locale, Locale(identifier: "ko_KR"))

        assertSnapshot(
            of: container,
            as: .image(layout: .fixed(width: width, height: height), traits: traits),
            file: file,
            testName: testName,
            line: line
        )
    }
}
