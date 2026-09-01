import SnapshotTesting
import SwiftUI
import XCTest

@testable import Pickflow

/// PV-40 — 보관함의 비공개 전환 표시. 케이스 정의는 docs/PV-40/ui-test-cases.md.
@MainActor
final class ArchivePrivateSpotSnapshotTests: XCTestCase {

    private static let light = UITraitCollection(userInterfaceStyle: .light)
    private static let dark = UITraitCollection(userInterfaceStyle: .dark)
    private static let a11yDark = UITraitCollection(traitsFrom: [
        UITraitCollection(userInterfaceStyle: .dark),
        UITraitCollection(preferredContentSizeCategory: .accessibilityExtraLarge),
    ])

    private let cardWidth: CGFloat = 175
    private let screenWidth: CGFloat = 390

    // MARK: - 카드

    func test_saved_card_private_light() {
        assert(card(notice: SavedSpotItem.fixture(isPrivate: true).unavailableNotice), width: cardWidth, height: 260, traits: Self.light)
    }

    func test_saved_card_private_dark() {
        assert(card(notice: SavedSpotItem.fixture(isPrivate: true).unavailableNotice), width: cardWidth, height: 260, traits: Self.dark)
    }

    func test_saved_card_private_a11y() {
        assert(card(notice: SavedSpotItem.fixture(isPrivate: true).unavailableNotice), width: cardWidth, height: 320, traits: Self.a11yDark)
    }

    func test_saved_card_deleted_light() {
        assert(card(notice: SavedSpotItem.fixture(deleted: true).unavailableNotice), width: cardWidth, height: 260, traits: Self.light)
    }

    func test_saved_card_deleted_dark() {
        assert(card(notice: SavedSpotItem.fixture(deleted: true).unavailableNotice), width: cardWidth, height: 260, traits: Self.dark)
    }

    func test_saved_card_default_light() {
        assert(card(notice: nil), width: cardWidth, height: 260, traits: Self.light)
    }

    func test_saved_card_default_dark() {
        assert(card(notice: nil), width: cardWidth, height: 260, traits: Self.dark)
    }

    // MARK: - 삭제 확인 팝업

    func test_saved_removal_popup_light() {
        assert(popup, width: screenWidth, height: 230, traits: Self.light)
    }

    func test_saved_removal_popup_dark() {
        assert(popup, width: screenWidth, height: 230, traits: Self.dark)
    }

    func test_saved_removal_popup_a11y() {
        assert(popup, width: screenWidth, height: 460, traits: Self.a11yDark)
    }

    // MARK: - Builders

    private func card(notice: String?) -> some View {
        SpotListCell(
            item: SpotListItem(
                spotId: 1,
                name: "스팟 등록 이름",
                theme: .reflection,
                thumbnailUrl: nil,
                distanceKm: 1.2,
                isBookmarked: true
            ),
            isBookmarked: true,
            likeCount: 34,
            onBookmarkTap: {},
            unavailableNotice: notice
        )
    }

    private var popup: some View {
        SavedSpotRemovalPopup(onCancel: {}, onConfirm: {})
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
