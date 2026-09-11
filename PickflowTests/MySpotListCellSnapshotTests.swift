import SnapshotTesting
import SwiftUI
import XCTest

@testable import Pickflow

/// PV-132 — 나의 스팟 카드 검수중/공개/반려 상태 뱃지(사진 좌측 하단, radius 4pt, gray20 15% 배경,
/// 반려는 테두리만).
@MainActor
final class MySpotListCellSnapshotTests: XCTestCase {

    private static let light = UITraitCollection(userInterfaceStyle: .light)
    private static let dark = UITraitCollection(userInterfaceStyle: .dark)

    private let cardWidth: CGFloat = 175
    private let cardHeight: CGFloat = 260

    // MARK: - 검수 중

    func test_badge_pending_light() {
        assert(card(status: .pending), traits: Self.light)
    }

    func test_badge_pending_dark() {
        assert(card(status: .pending), traits: Self.dark)
    }

    // MARK: - 공개

    func test_badge_published_light() {
        assert(card(status: .published), traits: Self.light)
    }

    func test_badge_published_dark() {
        assert(card(status: .published), traits: Self.dark)
    }

    // MARK: - 오픈 반려 (배경 없이 테두리만)

    func test_badge_rejected_light() {
        assert(card(status: .rejected), traits: Self.light)
    }

    func test_badge_rejected_dark() {
        assert(card(status: .rejected), traits: Self.dark)
    }

    // MARK: - 나만보기(뱃지 없음)

    func test_badge_none_draft_light() {
        assert(card(status: .draft), traits: Self.light)
    }

    func test_badge_none_draft_dark() {
        assert(card(status: .draft), traits: Self.dark)
    }

    // MARK: - Builders

    private func card(status: MySpotStatus) -> some View {
        MySpotListCell(item: .fixture(status: status))
    }

    private func assert(
        _ view: some View,
        traits: UITraitCollection,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let container = VStack(spacing: 0) { view }
            .frame(width: cardWidth, height: cardHeight)
            .background(UIAsset.Colors.gray95.swiftUIColor)
            .environment(\.locale, Locale(identifier: "ko_KR"))

        assertSnapshot(
            of: container,
            as: .image(layout: .fixed(width: cardWidth, height: cardHeight), traits: traits),
            file: file,
            testName: testName,
            line: line
        )
    }
}
