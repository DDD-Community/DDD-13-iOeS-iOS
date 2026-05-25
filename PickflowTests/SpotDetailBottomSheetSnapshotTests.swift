import SnapshotTesting
import SwiftUI
import XCTest

@testable import Pickflow

@MainActor
final class SpotDetailBottomSheetSnapshotTests: XCTestCase {

    private let defaultPreview = SpotPreviewResponse.fixture(
        addressRoad: "서울특별시 동작구 흑석한강로 100",
        addressJibun: "서울특별시 동작구 흑석동 100-1"
    )

    private static let dark = UITraitCollection(userInterfaceStyle: .dark)

    private static let sheetWidth: CGFloat = 390

    // MARK: - SheetChromeView 단독

    func test_sheetChrome_dark() {
        let view = SheetChromeView {
            UIAsset.Colors.gray95.swiftUIColor.frame(height: 200)
        }
        assertSnapshot(
            of: view,
            as: .image(layout: .fixed(width: Self.sheetWidth, height: 230), traits: Self.dark)
        )
    }

    // MARK: - SpotDetailSheetContentView

    func test_sheetContent_collapsedNotBookmarked_dark() {
        let view = sheetContent(preview: defaultPreview, isBookmarked: false, expanded: false)
        assertSnapshot(of: view, as: .image(traits: Self.dark))
    }

    func test_sheetContent_expandedNotBookmarked_dark() {
        let view = sheetContent(preview: defaultPreview, isBookmarked: false, expanded: true)
        assertSnapshot(of: view, as: .image(traits: Self.dark))
    }

    func test_sheetContent_collapsedBookmarked_dark() {
        let view = sheetContent(preview: defaultPreview, isBookmarked: true, expanded: false)
        assertSnapshot(of: view, as: .image(traits: Self.dark))
    }

    func test_sheetContent_longName_dark() {
        let longPreview = SpotPreviewResponse.fixture(
            name: "잠원 한강공원 노을 명소 윤슬이 가장 아름다운 곳",
            theme: .reflection
        )
        let view = sheetContent(preview: longPreview, isBookmarked: false, expanded: false)
        assertSnapshot(of: view, as: .image(traits: Self.dark))
    }

    func test_sheetContent_mySpot_dark() {
        let mySpot = SpotPreviewResponse.fixture(isMySpot: true, bookmarkCount: 0)
        let view = sheetContent(preview: mySpot, isBookmarked: false, expanded: false)
        assertSnapshot(of: view, as: .image(traits: Self.dark))
    }

    func test_sheetContent_dynamicTypeAXL_dark() {
        let view = sheetContent(preview: defaultPreview, isBookmarked: false, expanded: false)
            .environment(\.dynamicTypeSize, .accessibility3)
        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits, traits: Self.dark)
        )
    }

    // MARK: - Helpers

    private func sheetContent(preview: SpotPreviewResponse, isBookmarked: Bool, expanded: Bool) -> some View {
        SheetChromeView {
            SpotDetailSheetContentView(
                preview: preview,
                isBookmarked: isBookmarked,
                initialAddressExpanded: expanded
            )
        }
        .frame(width: Self.sheetWidth)
        .fixedSize(horizontal: false, vertical: true)
    }
}
