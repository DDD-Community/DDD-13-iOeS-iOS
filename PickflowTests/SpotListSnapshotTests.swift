import SnapshotTesting
import SwiftUI
import XCTest

@testable import Pickflow

@MainActor
final class SpotListSnapshotTests: XCTestCase {

    private static let light = UITraitCollection(userInterfaceStyle: .light)
    private static let dark = UITraitCollection(userInterfaceStyle: .dark)
    private static let a11yLight = UITraitCollection(traitsFrom: [
        UITraitCollection(userInterfaceStyle: .light),
        UITraitCollection(preferredContentSizeCategory: .accessibilityExtraLarge),
    ])

    private let screenSize = CGSize(width: 393, height: 852)
    private let cellWidth: CGFloat = 168
    private let filterBarWidth: CGFloat = 393

    // MARK: - Full Screen — loaded

    func test_spot_list_loaded_mixed_light() {
        assertSnapshot(of: screen(state: .loaded(items: mixedItems, hasNext: true)),
                       as: .image(layout: .fixed(width: screenSize.width, height: screenSize.height), traits: Self.light))
    }

    func test_spot_list_loaded_mixed_dark() {
        assertSnapshot(of: screen(state: .loaded(items: mixedItems, hasNext: true)),
                       as: .image(layout: .fixed(width: screenSize.width, height: screenSize.height), traits: Self.dark))
    }

    func test_spot_list_loaded_single_light() {
        assertSnapshot(of: screen(state: .loaded(items: [singleSunsetItem], hasNext: false)),
                       as: .image(layout: .fixed(width: screenSize.width, height: screenSize.height), traits: Self.light))
    }

    func test_spot_list_loaded_single_dark() {
        assertSnapshot(of: screen(state: .loaded(items: [singleSunsetItem], hasNext: false)),
                       as: .image(layout: .fixed(width: screenSize.width, height: screenSize.height), traits: Self.dark))
    }

    // MARK: - Full Screen — loading

    func test_spot_list_loading_light() {
        assertSnapshot(of: screen(state: .loading),
                       as: .image(layout: .fixed(width: screenSize.width, height: screenSize.height), traits: Self.light))
    }

    func test_spot_list_loading_dark() {
        assertSnapshot(of: screen(state: .loading),
                       as: .image(layout: .fixed(width: screenSize.width, height: screenSize.height), traits: Self.dark))
    }

    // MARK: - Full Screen — empty

    func test_spot_list_empty_light() {
        assertSnapshot(of: screen(state: .empty),
                       as: .image(layout: .fixed(width: screenSize.width, height: screenSize.height), traits: Self.light))
    }

    func test_spot_list_empty_dark() {
        assertSnapshot(of: screen(state: .empty),
                       as: .image(layout: .fixed(width: screenSize.width, height: screenSize.height), traits: Self.dark))
    }

    func test_spot_list_empty_a11y_light() {
        assertSnapshot(of: screen(state: .empty),
                       as: .image(layout: .fixed(width: screenSize.width, height: screenSize.height), traits: Self.a11yLight))
    }

    // MARK: - Full Screen — failed

    func test_spot_list_failed_light() {
        assertSnapshot(of: screen(state: .failed("네트워크 오류")),
                       as: .image(layout: .fixed(width: screenSize.width, height: screenSize.height), traits: Self.light))
    }

    func test_spot_list_failed_dark() {
        assertSnapshot(of: screen(state: .failed("네트워크 오류")),
                       as: .image(layout: .fixed(width: screenSize.width, height: screenSize.height), traits: Self.dark))
    }

    // MARK: - SortBar (무드 capsule 은 HomeMapView 헤더로 일원화 — §13a)

    func test_spot_list_sortbar_distance_collapsed_light() {
        assertSnapshot(of: sortBar(sort: .distance, expanded: false),
                       as: .image(layout: .fixed(width: filterBarWidth, height: 48), traits: Self.light))
    }

    func test_spot_list_sortbar_distance_collapsed_dark() {
        assertSnapshot(of: sortBar(sort: .distance, expanded: false),
                       as: .image(layout: .fixed(width: filterBarWidth, height: 48), traits: Self.dark))
    }

    func test_spot_list_sortbar_distance_expanded_dark() {
        assertSnapshot(of: sortBar(sort: .distance, expanded: true),
                       as: .image(layout: .fixed(width: filterBarWidth, height: 200), traits: Self.dark))
    }

    func test_spot_list_sortbar_recommended_collapsed_light() {
        assertSnapshot(of: sortBar(sort: .recommended, expanded: false),
                       as: .image(layout: .fixed(width: filterBarWidth, height: 48), traits: Self.light))
    }

    func test_spot_list_sortbar_recommended_expanded_dark() {
        assertSnapshot(of: sortBar(sort: .recommended, expanded: true),
                       as: .image(layout: .fixed(width: filterBarWidth, height: 200), traits: Self.dark))
    }

    // MARK: - Cell

    func test_spot_list_cell_sunset_bookmark_off_light() {
        assertSnapshot(of: cell(item: .fixture(spotId: 1, theme: .sunset, distanceKm: 1.2),
                                 isBookmarked: false, count: 12),
                       as: .image(layout: .fixed(width: cellWidth, height: 280), traits: Self.light))
    }

    func test_spot_list_cell_sunset_bookmark_off_dark() {
        assertSnapshot(of: cell(item: .fixture(spotId: 1, theme: .sunset, distanceKm: 1.2),
                                 isBookmarked: false, count: 12),
                       as: .image(layout: .fixed(width: cellWidth, height: 280), traits: Self.dark))
    }

    func test_spot_list_cell_sunset_bookmark_on_light() {
        assertSnapshot(of: cell(item: .fixture(spotId: 1, theme: .sunset, distanceKm: 1.2),
                                 isBookmarked: true, count: 13),
                       as: .image(layout: .fixed(width: cellWidth, height: 280), traits: Self.light))
    }

    func test_spot_list_cell_reflection_bookmark_off_light() {
        assertSnapshot(of: cell(item: .fixture(spotId: 1, name: "윤슬 스팟", theme: .reflection, distanceKm: 0.4),
                                 isBookmarked: false, count: 7),
                       as: .image(layout: .fixed(width: cellWidth, height: 280), traits: Self.light))
    }

    func test_spot_list_cell_reflection_bookmark_off_dark() {
        assertSnapshot(of: cell(item: .fixture(spotId: 1, name: "윤슬 스팟", theme: .reflection, distanceKm: 0.4),
                                 isBookmarked: false, count: 7),
                       as: .image(layout: .fixed(width: cellWidth, height: 280), traits: Self.dark))
    }

    func test_spot_list_cell_distance_nil_light() {
        assertSnapshot(of: cell(item: .fixture(spotId: 1, theme: .sunset, distanceKm: nil),
                                 isBookmarked: false, count: 12),
                       as: .image(layout: .fixed(width: cellWidth, height: 280), traits: Self.light))
    }

    func test_spot_list_cell_thumbnail_nil_light() {
        assertSnapshot(of: cell(item: .fixture(spotId: 1, theme: .sunset, thumbnailUrl: nil, distanceKm: 1.2),
                                 isBookmarked: false, count: 12),
                       as: .image(layout: .fixed(width: cellWidth, height: 280), traits: Self.light))
    }

    func test_spot_list_cell_long_name_truncate_light() {
        assertSnapshot(of: cell(item: .fixture(spotId: 1,
                                                name: "아주아주 긴 한강 노을 스팟 이름 테스트 케이스",
                                                theme: .sunset, distanceKm: 1.2),
                                 isBookmarked: false, count: 12),
                       as: .image(layout: .fixed(width: cellWidth, height: 280), traits: Self.light))
    }

    func test_spot_list_cell_a11y_light() {
        assertSnapshot(of: cell(item: .fixture(spotId: 1, theme: .sunset, distanceKm: 1.2),
                                 isBookmarked: false, count: 12),
                       as: .image(layout: .fixed(width: cellWidth, height: 420), traits: Self.a11yLight))
    }

    // MARK: - Factories

    private var mixedItems: [SpotListItem] {
        [
            .fixture(spotId: 1, name: "한강 노을", theme: .sunset, distanceKm: 0.8),
            .fixture(spotId: 2, name: "윤슬 한 바퀴", theme: .reflection, distanceKm: 1.3),
            .fixture(spotId: 3, name: "응봉산 노을", theme: .sunset, distanceKm: 2.1),
            .fixture(spotId: 4, name: "잠실 윤슬", theme: .reflection, distanceKm: 3.2),
            .fixture(spotId: 5, name: "선유도 노을", theme: .sunset, distanceKm: 4.4),
            .fixture(spotId: 6, name: "반포 윤슬", theme: .reflection, distanceKm: 5.0),
        ]
    }

    private var singleSunsetItem: SpotListItem {
        .fixture(spotId: 1, name: "한강 노을", theme: .sunset, distanceKm: 0.8)
    }

    private func screen(state: SpotListViewModel.LoadState) -> some View {
        SpotListScreenContent(
            state: state,
            isBookmarked: { _ in false },
            bookmarkCount: { _ in nil },
            onBookmarkTap: { _ in },
            onRetry: {},
            onAppearItem: { _ in }
        )
    }

    private func sortBar(sort: SpotListSort, expanded: Bool) -> some View {
        StatefulPreviewWrapper(initial: expanded) { isExpanded in
            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Spacer()
                    SpotListSortDropdownHeader(sort: sort, isExpanded: isExpanded)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                if isExpanded.wrappedValue {
                    SpotListSortDropdownOptions(current: sort, onSelect: { _ in })
                        .padding(.trailing, 16)
                }
                Spacer(minLength: 0)
            }
            .background(UIAsset.Colors.gray95.swiftUIColor)
        }
    }

    private func cell(item: SpotListItem, isBookmarked: Bool, count: Int?) -> some View {
        SpotListCell(
            item: item,
            isBookmarked: isBookmarked,
            bookmarkCount: count,
            onBookmarkTap: {}
        )
        .padding(8)
        .background(UIAsset.Colors.gray95.swiftUIColor)
    }
}

/// 스냅샷 한정 — `@State` 초기값을 외부에서 강제 주입하기 위한 유틸.
private struct StatefulPreviewWrapper<Content: View, Value>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content

    init(initial: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: initial)
        self.content = content
    }

    var body: some View { content($value) }
}
