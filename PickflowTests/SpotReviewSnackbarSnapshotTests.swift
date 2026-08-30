import SnapshotTesting
import SwiftUI
import XCTest

@testable import Pickflow

/// PV-40 — 검수 결과 스낵바. 케이스 정의는 docs/PV-40/ui-test-cases.md.
@MainActor
final class SpotReviewSnackbarSnapshotTests: XCTestCase {

    private static let light = UITraitCollection(userInterfaceStyle: .light)
    private static let dark = UITraitCollection(userInterfaceStyle: .dark)
    private static let a11yLight = UITraitCollection(traitsFrom: [
        UITraitCollection(userInterfaceStyle: .light),
        UITraitCollection(preferredContentSizeCategory: .accessibilityExtraLarge),
    ])

    func test_review_snackbar_approved_light() {
        assert(.approved, height: 110, traits: Self.light)
    }

    func test_review_snackbar_approved_dark() {
        assert(.approved, height: 110, traits: Self.dark)
    }

    func test_review_snackbar_rejected_light() {
        assert(.rejected, height: 110, traits: Self.light)
    }

    func test_review_snackbar_rejected_dark() {
        assert(.rejected, height: 110, traits: Self.dark)
    }

    func test_review_snackbar_rejected_a11y() {
        assert(.rejected, height: 300, traits: Self.a11yLight)
    }

    private func assert(
        _ kind: SpotReviewNotice.Kind,
        height: CGFloat,
        traits: UITraitCollection,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let view = SpotReviewSnackbar(
            notice: SpotReviewNotice(spotId: 1, kind: kind),
            onAction: {},
            onClose: {}
        )
        .padding(.horizontal, 16)
        .frame(width: 390, height: height)
        .background(UIAsset.Colors.gray80.swiftUIColor)
        .environment(\.locale, Locale(identifier: "ko_KR"))

        assertSnapshot(
            of: view,
            as: .image(layout: .fixed(width: 390, height: height), traits: traits),
            file: file,
            testName: testName,
            line: line
        )
    }
}
