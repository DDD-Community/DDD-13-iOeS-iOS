import SnapshotTesting
import SwiftUI
import UIKit
import XCTest

@testable import Pickflow

@MainActor
final class SpotDetailBottomSheetSnapshotTests: XCTestCase {

    private let defaultSpot = SpotDetail.fixture()
    private let longNameSpot = SpotDetail.fixture(
        comment: "걷다 보면 멀리 노을이 번져요."
    )

    private static let dark = UITraitCollection(userInterfaceStyle: .dark)
    private static let darkAXL = UITraitCollection(traitsFrom: [
        UITraitCollection(userInterfaceStyle: .dark),
        UITraitCollection(preferredContentSizeCategory: .accessibilityExtraLarge),
    ])

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
        let view = sheetContent(spot: defaultSpot, isBookmarked: false, expanded: false)
        assertSnapshot(of: view, as: .image(traits: Self.dark))
    }

    func test_sheetContent_expandedNotBookmarked_dark() {
        let view = sheetContent(spot: defaultSpot, isBookmarked: false, expanded: true)
        assertSnapshot(of: view, as: .image(traits: Self.dark))
    }

    func test_sheetContent_collapsedBookmarked_dark() {
        let view = sheetContent(spot: defaultSpot, isBookmarked: true, expanded: false)
        assertSnapshot(of: view, as: .image(traits: Self.dark))
    }

    func test_sheetContent_longName_dark() {
        let longSpot = SpotDetail.fixtureLongName()
        let view = sheetContent(spot: longSpot, isBookmarked: false, expanded: false)
        assertSnapshot(of: view, as: .image(traits: Self.dark))
    }

    func test_sheetContent_mySpot_dark() {
        let mySpot = SpotDetail.fixture(isMySpot: true)
        let view = sheetContent(spot: mySpot, isBookmarked: false, expanded: false)
        assertSnapshot(of: view, as: .image(traits: Self.dark))
    }

    func test_sheetContent_dynamicTypeAXL_dark() {
        let view = sheetContent(spot: defaultSpot, isBookmarked: false, expanded: false)
            .environment(\.dynamicTypeSize, .accessibility3)
        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits, traits: Self.dark)
        )
    }

    // MARK: - Helpers

    private func sheetContent(spot: SpotDetail, isBookmarked: Bool, expanded: Bool) -> some View {
        SheetChromeView {
            SpotDetailSheetContentView(
                spot: spot,
                isBookmarked: isBookmarked,
                initialAddressExpanded: expanded
            )
        }
        .frame(width: Self.sheetWidth)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private extension SpotDetail {
    static func fixtureLongName() -> SpotDetail {
        SpotDetail(
            id: 1,
            name: "잠원 한강공원 노을 명소 윤슬이 가장 아름다운 곳",
            comment: "걷다 보면 멀리 노을이 번져요.",
            theme: .reflection,
            latitude: 37.501,
            longitude: 126.951,
            address: "서울 동작구",
            imageUrl: "https://example.com/spot.jpg",
            recordedTime: "19:30",
            isBookmarked: false,
            bookmarkCount: 34,
            isMySpot: false,
            weather: SpotWeather(
                precipitationProbability: 15,
                condition: .clear,
                sunsetTime: "18:40",
                congestion: .relaxed,
                parking: "무료 주차장"
            )
        )
    }
}
