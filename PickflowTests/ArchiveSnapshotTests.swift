import SnapshotTesting
import SwiftUI
import UIKit
import XCTest

@testable import Pickflow

@MainActor
final class ArchiveSnapshotTests: XCTestCase {

    // MARK: - Trait constants

    private static let light = UITraitCollection(userInterfaceStyle: .light)
    private static let dark = UITraitCollection(userInterfaceStyle: .dark)
    private static let a11yDark = UITraitCollection(traitsFrom: [
        UITraitCollection(userInterfaceStyle: .dark),
        UITraitCollection(preferredContentSizeCategory: .accessibilityExtraLarge),
    ])

    private typealias L = ArchiveSnapshotTests

    // MARK: - ArchiveView: Signed Out

    func test_archive_root_signed_out_light() {
        assertSnapshot(
            of: rootScreen(state: .signedOut),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_archive_root_signed_out_dark() {
        assertSnapshot(
            of: rootScreen(state: .signedOut),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - ArchiveView: Loading

    func test_archive_root_loading_light() {
        assertSnapshot(
            of: rootScreen(state: .loading),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_archive_root_loading_dark() {
        assertSnapshot(
            of: rootScreen(state: .loading),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - ArchiveView: Loaded

    func test_archive_root_loaded_light() {
        assertSnapshot(
            of: rootScreen(state: .loaded(items: mockItems, hasNext: false)),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_archive_root_loaded_dark() {
        assertSnapshot(
            of: rootScreen(state: .loaded(items: mockItems, hasNext: false)),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - ArchiveView: Empty

    func test_archive_root_empty_light() {
        assertSnapshot(
            of: rootScreen(state: .empty),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_archive_root_empty_dark() {
        assertSnapshot(
            of: rootScreen(state: .empty),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - ArchiveView: Failed

    func test_archive_root_failed_light() {
        assertSnapshot(
            of: rootScreen(state: .failed("네트워크 연결을 확인해주세요.")),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_archive_root_failed_dark() {
        assertSnapshot(
            of: rootScreen(state: .failed("네트워크 연결을 확인해주세요.")),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - ArchiveSignedOutContent

    func test_archive_signed_out_content_light() {
        assertSnapshot(
            of: signedOutContentScreen(isLoading: false),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_archive_signed_out_content_dark() {
        assertSnapshot(
            of: signedOutContentScreen(isLoading: false),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    func test_archive_signed_out_content_accessibility_dark() {
        assertSnapshot(
            of: signedOutContentScreen(isLoading: false),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.a11yDark)
        )
    }

    func test_archive_signed_out_loading_dark() {
        assertSnapshot(
            of: signedOutContentScreen(isLoading: true),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - ArchiveHeaderView

    func test_archive_header_expanded_light() {
        assertSnapshot(
            of: headerScreen(thumbnailURL: nil),
            as: .image(layout: .fixed(width: 393, height: 240), traits: L.light)
        )
    }

    func test_archive_header_expanded_dark() {
        assertSnapshot(
            of: headerScreen(thumbnailURL: nil),
            as: .image(layout: .fixed(width: 393, height: 240), traits: L.dark)
        )
    }

    // MARK: - ArchiveTabBar

    func test_archive_tab_bar_saved_light() {
        assertSnapshot(
            of: tabBarScreen(selectedTab: .savedSpots),
            as: .image(layout: .fixed(width: 393, height: 48), traits: L.light)
        )
    }

    func test_archive_tab_bar_saved_dark() {
        assertSnapshot(
            of: tabBarScreen(selectedTab: .savedSpots),
            as: .image(layout: .fixed(width: 393, height: 48), traits: L.dark)
        )
    }

    func test_archive_tab_bar_myspot_light() {
        assertSnapshot(
            of: tabBarScreen(selectedTab: .mySpots),
            as: .image(layout: .fixed(width: 393, height: 48), traits: L.light)
        )
    }

    func test_archive_tab_bar_myspot_dark() {
        assertSnapshot(
            of: tabBarScreen(selectedTab: .mySpots),
            as: .image(layout: .fixed(width: 393, height: 48), traits: L.dark)
        )
    }

    // MARK: - ArchiveMySpotPlaceholder

    func test_archive_myspot_placeholder_light() {
        assertSnapshot(
            of: rootScreen(state: .loaded(items: mockItems, hasNext: false), selectedTab: .mySpots),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_archive_myspot_placeholder_dark() {
        assertSnapshot(
            of: rootScreen(state: .loaded(items: mockItems, hasNext: false), selectedTab: .mySpots),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    // MARK: - ArchiveEmptyView

    func test_archive_empty_view_light() {
        assertSnapshot(
            of: emptyViewScreen(),
            as: .image(layout: .fixed(width: 393, height: 400), traits: L.light)
        )
    }

    func test_archive_empty_view_dark() {
        assertSnapshot(
            of: emptyViewScreen(),
            as: .image(layout: .fixed(width: 393, height: 400), traits: L.dark)
        )
    }

    // MARK: - ArchiveLoadedGrid

    func test_archive_loaded_grid_light() {
        assertSnapshot(
            of: loadedGridScreen(items: mockItems),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.light)
        )
    }

    func test_archive_loaded_grid_dark() {
        assertSnapshot(
            of: loadedGridScreen(items: mockItems),
            as: .image(layout: .fixed(width: 393, height: 852), traits: L.dark)
        )
    }

    func test_archive_loaded_grid_accessibility_dark() {
        assertSnapshot(
            of: loadedGridScreen(items: Array(mockItems.prefix(4))),
            as: .image(layout: .fixed(width: 393, height: 600), traits: L.a11yDark)
        )
    }

    // MARK: - View Factories

    private func rootScreen(
        state: ArchiveViewModel.LoadState,
        selectedTab: ArchiveTab = .savedSpots
    ) -> some View {
        ArchiveScreenContent(state: state, selectedTab: selectedTab)
            .snapshotEnvironment(colorScheme: .dark)
    }

    private func signedOutContentScreen(isLoading: Bool) -> some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()
            ArchiveSignedOutContent(isLoading: isLoading)
        }
        .snapshotEnvironment(colorScheme: .dark)
    }

    private func headerScreen(thumbnailURL: URL?) -> some View {
        ArchiveHeaderView(thumbnailURL: thumbnailURL)
            .snapshotEnvironment(colorScheme: .dark)
    }

    private func tabBarScreen(selectedTab: ArchiveTab) -> some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()
            ArchiveTabBar(selectedTab: selectedTab, onTabChange: { _ in })
        }
        .snapshotEnvironment(colorScheme: .dark)
    }

    private func emptyViewScreen() -> some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()
            ArchiveEmptyView()
        }
        .snapshotEnvironment(colorScheme: .dark)
    }

    private func loadedGridScreen(items: [SpotListItem]) -> some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()
            ScrollView {
                MasonryTwoColumn(items: items) { item in
                    SpotListCell(
                        item: item,
                        isBookmarked: true,
                        bookmarkCount: nil,
                        onBookmarkTap: {}
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .snapshotEnvironment(colorScheme: .dark)
    }

    // MARK: - Mock Data

    private let mockItems: [SpotListItem] = (1...8).map { i in
        SpotListItem(
            spotId: Int64(i),
            name: ["한강 노을길", "잠실 윤슬", "응봉산 전망대", "반포 분수", "선유도 일몰", "광나루 윤슬길", "노들섬 노을 뷰", "성수 한강"][i - 1],
            theme: i.isMultiple(of: 2) ? .reflection : .sunset,
            thumbnailUrl: nil,
            distanceKm: Double(i) * 0.8
        )
    }
}
