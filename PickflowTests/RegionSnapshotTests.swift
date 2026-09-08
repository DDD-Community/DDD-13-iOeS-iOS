import SnapshotTesting
import SwiftUI
import XCTest

@testable import Pickflow

@MainActor
final class RegionSnapshotTests: XCTestCase {
    private static let dark = UITraitCollection(userInterfaceStyle: .dark)
    private static let sheetWidth: CGFloat = 390

    // MARK: - RegionPickerHeader

    // `.sizeThatFits` 레이아웃은 `.pretendard()`(내부 `.lineSpacing()`) 스타일 Text를 0 크기로
    // 잘못 측정하는 SwiftUI/SnapshotTesting 이슈가 있어, 헤더류는 `.fixed` 레이아웃을 쓴다.
    func test_pickerHeader_daejeon_dark() {
        let view = RegionPickerHeader(regionName: "대전") {}
            .padding(16)
            .background(Color.black)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 260, height: 64), traits: Self.dark))
    }

    func test_pickerHeader_seoul_dark() {
        let view = RegionPickerHeader(regionName: "서울") {}
            .padding(16)
            .background(Color.black)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 260, height: 64), traits: Self.dark))
    }

    // MARK: - RegionSelectionSheet

    func test_selectionSheet_daejeonSelected_dark() {
        let view = RegionSelectionSheet(
            regions: Region.fallbackRegions,
            appliedRegion: Region.fallbackRegions.first,
            onApply: { _ in },
            onCancel: {}
        )
        assertSnapshot(
            of: view,
            as: .image(layout: .fixed(width: Self.sheetWidth, height: 392), traits: Self.dark)
        )
    }

    func test_selectionSheet_seoulSelected_dark() {
        let view = RegionSelectionSheet(
            regions: Region.fallbackRegions,
            appliedRegion: Region.fallbackRegions[1],
            onApply: { _ in },
            onCancel: {}
        )
        assertSnapshot(
            of: view,
            as: .image(layout: .fixed(width: Self.sheetWidth, height: 392), traits: Self.dark)
        )
    }
}
