import SnapshotTesting
import SwiftUI
import XCTest

@testable import Pickflow

/// PV-40 — 지도 미리보기 시트의 출처 표기와 추천 수. 케이스 정의는 docs/PV-40/ui-test-cases.md.
@MainActor
final class SpotPreviewSheetSnapshotTests: XCTestCase {

    private static let light = UITraitCollection(userInterfaceStyle: .light)
    private static let dark = UITraitCollection(userInterfaceStyle: .dark)
    private static let a11yDark = UITraitCollection(traitsFrom: [
        UITraitCollection(userInterfaceStyle: .dark),
        UITraitCollection(preferredContentSizeCategory: .accessibilityExtraLarge),
    ])

    func test_preview_sheet_user_spot_light() {
        assert(sheet(isMySpot: false, isCurated: false), height: 480, traits: Self.light)
    }

    func test_preview_sheet_user_spot_dark() {
        assert(sheet(isMySpot: false, isCurated: false), height: 480, traits: Self.dark)
    }

    func test_preview_sheet_curated_light() {
        assert(sheet(isMySpot: false, isCurated: true), height: 480, traits: Self.light)
    }

    func test_preview_sheet_curated_dark() {
        assert(sheet(isMySpot: false, isCurated: true), height: 480, traits: Self.dark)
    }

    func test_preview_sheet_my_spot_light() {
        assert(sheet(isMySpot: true, isCurated: false), height: 480, traits: Self.light)
    }

    func test_preview_sheet_user_spot_a11y() {
        assert(sheet(isMySpot: false, isCurated: false), height: 700, traits: Self.a11yDark)
    }

    // MARK: - Builders

    private func sheet(isMySpot: Bool, isCurated: Bool) -> some View {
        SpotDetailSheetContentView(
            preview: .fixture(
                name: "잠원 한강공원",
                isMySpot: isMySpot,
                theme: .sunlight,
                isCurated: isCurated,
                likeCount: 34
            ),
            isBookmarked: false
        )
    }

    private func assert(
        _ view: some View,
        height: CGFloat,
        traits: UITraitCollection,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let container = VStack(spacing: 0) { view }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .frame(width: 390, height: height, alignment: .top)
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
