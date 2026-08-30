import SnapshotTesting
import SwiftUI
import XCTest

@testable import Pickflow

/// 카테고리 4개 확장 후 칩이 한 줄에 들어가는지 눈으로 확인하기 위한 스냅샷.
/// 디자인 실측(칩 84×40, 간격 8)에서 4개 기준 폭이 360 이라 경계에 걸린다.
@MainActor
final class SpotThemeChipSnapshotTests: XCTestCase {

    private static let light = UITraitCollection(userInterfaceStyle: .light)
    private static let dark = UITraitCollection(userInterfaceStyle: .dark)

    /// 393(iPhone 17) 화면에서 좌우 여백 16 을 뺀 실제 가용 폭.
    private let barWidth: CGFloat = 361
    /// 390(iPhone 15 등) 화면 기준. 2pt 부족해 스크롤이 필요한 경계 케이스.
    private let narrowBarWidth: CGFloat = 358

    // MARK: - 탐색 상단 필터

    func test_filter_bar_none_selected_dark() {
        assertSnapshot(
            of: filterBar(selected: [], width: barWidth),
            as: .image(layout: .fixed(width: barWidth, height: 40), traits: Self.dark)
        )
    }

    func test_filter_bar_none_selected_light() {
        assertSnapshot(
            of: filterBar(selected: [], width: barWidth),
            as: .image(layout: .fixed(width: barWidth, height: 40), traits: Self.light)
        )
    }

    func test_filter_bar_single_selected_dark() {
        assertSnapshot(
            of: filterBar(selected: [.sunlight], width: barWidth),
            as: .image(layout: .fixed(width: barWidth, height: 40), traits: Self.dark)
        )
    }

    func test_filter_bar_multi_selected_dark() {
        assertSnapshot(
            of: filterBar(selected: [.sunlight, .sunset, .nightView], width: barWidth),
            as: .image(layout: .fixed(width: barWidth, height: 40), traits: Self.dark)
        )
    }

    /// 390pt 기기에서 마지막 칩이 잘리는지 확인하는 경계 케이스.
    func test_filter_bar_narrow_width_dark() {
        assertSnapshot(
            of: filterBar(selected: [.nightView], width: narrowBarWidth),
            as: .image(layout: .fixed(width: narrowBarWidth, height: 40), traits: Self.dark)
        )
    }

    // MARK: - 등록폼 카테고리

    /// 등록폼은 ScrollView 콘텐츠에 `.padding(.horizontal, 16)` 이 걸려 있어
    /// 393 화면에서 가용 폭이 필터 바와 같은 361 이다.
    func test_registration_chip_group_none_selected_dark() {
        assertSnapshot(
            of: registrationChips(selected: nil),
            as: .image(layout: .fixed(width: 393, height: 90), traits: Self.dark)
        )
    }

    func test_registration_chip_group_selected_dark() {
        assertSnapshot(
            of: registrationChips(selected: .nightView),
            as: .image(layout: .fixed(width: 393, height: 90), traits: Self.dark)
        )
    }

    // MARK: - Builders

    private func filterBar(selected: Set<SpotTheme>, width: CGFloat) -> some View {
        SpotThemeFilterBar(selectedThemes: .constant(selected))
            .frame(width: width, alignment: .leading)
            .background(Color.black)
            .snapshotEnvironment(colorScheme: .dark)
    }

    private func registrationChips(selected: SpotTheme?) -> some View {
        SpotThemeChipGroup(selectedCategory: .constant(selected))
            .padding(.horizontal, 16)
            .background(Color.spotBackground)
            .snapshotEnvironment(colorScheme: .dark)
    }
}
