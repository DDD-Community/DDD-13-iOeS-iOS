import SnapshotTesting
import SwiftUI
import XCTest

@testable import Pickflow

/// V2 업데이트 안내 모달. 케이스 정의는 docs/PV-40/ui-test-cases.md.
@MainActor
final class V2UpdateNoticeSnapshotTests: XCTestCase {

    private static let light = UITraitCollection(userInterfaceStyle: .light)
    private static let dark = UITraitCollection(userInterfaceStyle: .dark)
    private static let a11yDark = UITraitCollection(traitsFrom: [
        UITraitCollection(userInterfaceStyle: .dark),
        UITraitCollection(preferredContentSizeCategory: .accessibilityExtraLarge),
    ])

    func test_v2_notice_modal_light() {
        assert(height: 300, traits: Self.light)
    }

    func test_v2_notice_modal_dark() {
        assert(height: 300, traits: Self.dark)
    }

    func test_v2_notice_modal_a11y() {
        assert(height: 560, traits: Self.a11yDark)
    }

    private func assert(
        height: CGFloat,
        traits: UITraitCollection,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let container = VStack(spacing: 0) { V2UpdateNoticeModal(onConfirm: {}) }
            .frame(width: 390, height: height)
            .background(UIAsset.Colors.gray95.swiftUIColor)
            .environment(\.locale, Locale(identifier: "ko_KR"))

        assertSnapshot(
            of: container,
            as: .image(layout: .fixed(width: 390, height: height), traits: traits),
            file: file,
            testName: testName,
            line: line
        )
    }
}
