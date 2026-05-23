import SnapshotTesting
import SwiftUI
import XCTest

@testable import Pickflow

@MainActor
final class SpotDetailSnapshotTests: XCTestCase {

    // MARK: - Fixtures

    private let defaultSpot = SpotDetail.fixture()
    private let bookmarkedSpot = SpotDetail.fixture(isBookmarked: true)
    private let mineSpot = SpotDetail.fixture(isMySpot: true)
    private let reflectionSpot = SpotDetail.fixture(theme: .reflection)
    private let noImageSpot = SpotDetail.fixture(imageUrl: nil)
    private let longCommentSpot = SpotDetail.fixture(comment: "걷다 보면 멀리 노을이 번져요.\n하늘 비율을 크게 잡아보세요.\n이 구간은 특히 빛이 아름답습니다.")

    private static let light = UITraitCollection(userInterfaceStyle: .light)
    private static let dark = UITraitCollection(userInterfaceStyle: .dark)
    private static let a11yLight = UITraitCollection(traitsFrom: [
        UITraitCollection(userInterfaceStyle: .light),
        UITraitCollection(preferredContentSizeCategory: .accessibilityExtraLarge),
    ])

    // MARK: - Full Screen — Loading

    func test_screen_loading_light() {
        assertSnapshot(of: loadingScreen(), as: .image(layout: .fixed(width: 393, height: 852), traits: Self.light))
    }

    func test_screen_loading_dark() {
        assertSnapshot(of: loadingScreen(), as: .image(layout: .fixed(width: 393, height: 852), traits: Self.dark))
    }

    // MARK: - Full Screen — Error

    func test_screen_error_light() {
        assertSnapshot(of: errorScreen(), as: .image(layout: .fixed(width: 393, height: 852), traits: Self.light))
    }

    func test_screen_error_dark() {
        assertSnapshot(of: errorScreen(), as: .image(layout: .fixed(width: 393, height: 852), traits: Self.dark))
    }

    // MARK: - Full Screen — Loaded Default

    func test_screen_loaded_default_light() {
        assertSnapshot(of: loadedScreen(spot: defaultSpot, isBookmarked: false), as: .image(layout: .fixed(width: 393, height: 852), traits: Self.light))
    }

    func test_screen_loaded_default_dark() {
        assertSnapshot(of: loadedScreen(spot: defaultSpot, isBookmarked: false), as: .image(layout: .fixed(width: 393, height: 852), traits: Self.dark))
    }

    func test_screen_loaded_bookmarked_light() {
        assertSnapshot(of: loadedScreen(spot: bookmarkedSpot, isBookmarked: true), as: .image(layout: .fixed(width: 393, height: 852), traits: Self.light))
    }

    func test_screen_loaded_bookmarked_dark() {
        assertSnapshot(of: loadedScreen(spot: bookmarkedSpot, isBookmarked: true), as: .image(layout: .fixed(width: 393, height: 852), traits: Self.dark))
    }

    func test_screen_loaded_mine_light() {
        assertSnapshot(of: loadedScreen(spot: mineSpot, isBookmarked: false), as: .image(layout: .fixed(width: 393, height: 852), traits: Self.light))
    }

    func test_screen_loaded_mine_dark() {
        assertSnapshot(of: loadedScreen(spot: mineSpot, isBookmarked: false), as: .image(layout: .fixed(width: 393, height: 852), traits: Self.dark))
    }

    // MARK: - SpotDetailNavBar

    func test_navbar_default_light() {
        assertSnapshot(of: navBarView(), as: .image(layout: .fixed(width: 393, height: 48), traits: Self.light))
    }

    func test_navbar_default_dark() {
        assertSnapshot(of: navBarView(), as: .image(layout: .fixed(width: 393, height: 48), traits: Self.dark))
    }

    func test_navbar_mine_light() {
        assertSnapshot(of: navBarView(), as: .image(layout: .fixed(width: 393, height: 48), traits: Self.light))
    }

    // MARK: - SpotHeaderSection

    func test_header_sunset_light() {
        assertSnapshot(of: headerView(spot: defaultSpot), as: .image(layout: .fixed(width: 361, height: 200), traits: Self.light))
    }

    func test_header_sunset_dark() {
        assertSnapshot(of: headerView(spot: defaultSpot), as: .image(layout: .fixed(width: 361, height: 200), traits: Self.dark))
    }

    func test_header_reflection_light() {
        assertSnapshot(of: headerView(spot: reflectionSpot), as: .image(layout: .fixed(width: 361, height: 200), traits: Self.light))
    }

    func test_header_reflection_dark() {
        assertSnapshot(of: headerView(spot: reflectionSpot), as: .image(layout: .fixed(width: 361, height: 200), traits: Self.dark))
    }

    func test_header_mine_light() {
        assertSnapshot(of: headerView(spot: mineSpot), as: .image(layout: .fixed(width: 361, height: 200), traits: Self.light))
    }

    func test_header_mine_dark() {
        assertSnapshot(of: headerView(spot: mineSpot), as: .image(layout: .fixed(width: 361, height: 200), traits: Self.dark))
    }

    func test_header_long_comment_light() {
        assertSnapshot(of: headerView(spot: longCommentSpot), as: .image(layout: .fixed(width: 361, height: 300), traits: Self.light))
    }

    func test_header_a11y_light() {
        assertSnapshot(of: headerView(spot: defaultSpot), as: .image(layout: .fixed(width: 361, height: 300), traits: Self.a11yLight))
    }

    // MARK: - SpotPhotoSection

    func test_photo_withImage_light() {
        assertSnapshot(of: photoView(spot: defaultSpot), as: .image(layout: .fixed(width: 361, height: 240), traits: Self.light))
    }

    func test_photo_withImage_dark() {
        assertSnapshot(of: photoView(spot: defaultSpot), as: .image(layout: .fixed(width: 361, height: 240), traits: Self.dark))
    }

    func test_photo_noImage_light() {
        assertSnapshot(of: photoView(spot: noImageSpot), as: .image(layout: .fixed(width: 361, height: 240), traits: Self.light))
    }

    func test_photo_noImage_dark() {
        assertSnapshot(of: photoView(spot: noImageSpot), as: .image(layout: .fixed(width: 361, height: 240), traits: Self.dark))
    }

    // MARK: - SpotActionButtons

    func test_action_unbookmarked_light() {
        assertSnapshot(of: actionView(isMine: false, isBookmarked: false), as: .image(layout: .fixed(width: 361, height: 68), traits: Self.light))
    }

    func test_action_unbookmarked_dark() {
        assertSnapshot(of: actionView(isMine: false, isBookmarked: false), as: .image(layout: .fixed(width: 361, height: 68), traits: Self.dark))
    }

    func test_action_bookmarked_light() {
        assertSnapshot(of: actionView(isMine: false, isBookmarked: true), as: .image(layout: .fixed(width: 361, height: 68), traits: Self.light))
    }

    func test_action_bookmarked_dark() {
        assertSnapshot(of: actionView(isMine: false, isBookmarked: true), as: .image(layout: .fixed(width: 361, height: 68), traits: Self.dark))
    }

    func test_action_mine_light() {
        assertSnapshot(of: actionView(isMine: true, isBookmarked: false), as: .image(layout: .fixed(width: 361, height: 64), traits: Self.light))
    }

    func test_action_mine_dark() {
        assertSnapshot(of: actionView(isMine: true, isBookmarked: false), as: .image(layout: .fixed(width: 361, height: 64), traits: Self.dark))
    }

    // MARK: - SpotRealTimeInfoSection

    func test_realtime_default_light() {
        assertSnapshot(of: realtimeView(spot: defaultSpot), as: .image(layout: .fixed(width: 361, height: 300), traits: Self.light))
    }

    func test_realtime_default_dark() {
        assertSnapshot(of: realtimeView(spot: defaultSpot), as: .image(layout: .fixed(width: 361, height: 300), traits: Self.dark))
    }

    func test_realtime_mine_light() {
        assertSnapshot(of: realtimeView(spot: mineSpot), as: .image(layout: .fixed(width: 361, height: 300), traits: Self.light))
    }

    func test_realtime_mine_dark() {
        assertSnapshot(of: realtimeView(spot: mineSpot), as: .image(layout: .fixed(width: 361, height: 300), traits: Self.dark))
    }

    func test_realtime_a11y_light() {
        assertSnapshot(of: realtimeView(spot: defaultSpot), as: .image(layout: .fixed(width: 361, height: 400), traits: Self.a11yLight))
    }

    // MARK: - View Factories

    private func loadingScreen() -> some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()
            ProgressView()
                .tint(UIAsset.Colors.gray0.color)
        }
    }

    private func errorScreen() -> some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()
            VStack(spacing: 12) {
                Text("스팟 정보를 불러오지 못했어요.")
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(.gray0)
                Text("오류 메시지")
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray50)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
    }

    private func loadedScreen(spot: SpotDetail, isBookmarked: Bool) -> some View {
        ZStack {
            UIAsset.Colors.gray95.color
            VStack(spacing: 0) {
                SpotDetailNavBar(onShare: {}, onClose: {})
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        SpotHeaderSection(spot: spot)
                        SpotPhotoSection(
                            imageURL: spot.imageUrl,
                            recordedTime: spot.recordedTime,
                            address: spot.address
                        )
                        SpotActionButtons(
                            isMine: spot.isMySpot,
                            isBookmarked: isBookmarked,
                            onRoute: {}, onBookmark: {}, onOpenSpot: {}
                        )
                        SpotRealTimeInfoSection(spot: spot)
                        ReportButton(action: {})
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func navBarView() -> some View {
        SpotDetailNavBar(onShare: {}, onClose: {})
    }

    private func headerView(spot: SpotDetail) -> some View {
        SpotHeaderSection(spot: spot)
            .padding(16)
            .background(UIAsset.Colors.gray95.color)
    }

    private func photoView(spot: SpotDetail) -> some View {
        SpotPhotoSection(
            imageURL: spot.imageUrl,
            recordedTime: spot.recordedTime,
            address: spot.address
        )
        .padding(.horizontal, 16)
        .background(UIAsset.Colors.gray95.color)
    }

    private func actionView(isMine: Bool, isBookmarked: Bool) -> some View {
        SpotActionButtons(
            isMine: isMine,
            isBookmarked: isBookmarked,
            onRoute: {}, onBookmark: {}, onOpenSpot: {}
        )
        .padding(.horizontal, 16)
        .background(UIAsset.Colors.gray95.color)
    }

    private func realtimeView(spot: SpotDetail) -> some View {
        SpotRealTimeInfoSection(spot: spot)
            .padding(16)
            .background(UIAsset.Colors.gray95.color)
    }
}
