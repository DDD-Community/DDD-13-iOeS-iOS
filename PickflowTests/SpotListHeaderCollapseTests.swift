import SwiftUI
import XCTest

@testable import Pickflow

/// 탐색 탭 리스트 스크롤 → 헤더(로고+지역) 접힘 높이 계산 (PV-147).
@MainActor
final class SpotListHeaderCollapseTests: XCTestCase {

    // MARK: - 계산

    func test_headerCollapse_맨위에서는_헤더를_접지않는다() {
        XCTAssertEqual(SpotListScreenContent.headerCollapse(scrollOffset: 0, collapsibleHeight: 42), 0)
    }

    func test_headerCollapse_당겨서튕기는_음수오프셋은_0이다() {
        XCTAssertEqual(SpotListScreenContent.headerCollapse(scrollOffset: -60, collapsibleHeight: 42), 0)
    }

    func test_headerCollapse_접히는높이_안에서는_스크롤만큼_접는다() {
        XCTAssertEqual(SpotListScreenContent.headerCollapse(scrollOffset: 20, collapsibleHeight: 42), 20)
    }

    func test_headerCollapse_접히는높이를_넘으면_그높이에서_멈춘다() {
        XCTAssertEqual(SpotListScreenContent.headerCollapse(scrollOffset: 42, collapsibleHeight: 42), 42)
        XCTAssertEqual(SpotListScreenContent.headerCollapse(scrollOffset: 500, collapsibleHeight: 42), 42)
    }

    // MARK: - 실제 ScrollView 연동 (contentMargins 가 있어도 맨 위 기준 오프셋으로 계산되는지)

    func test_리스트스크롤시_contentTopInset과_무관하게_스크롤한만큼_헤더접힘을_보고한다() async throws {
        var reported: [CGFloat] = []
        let view = SpotListScreenContent(
            state: .loaded(items: (1...20).map { .fixture(spotId: Int64($0), name: "스팟 \($0)", thumbnailUrl: nil) }, hasNext: false),
            isBookmarked: { _ in false },
            onBookmarkTap: { _ in },
            onRetry: {},
            onAppearItem: { _ in },
            contentTopInset: 150,
            collapsibleHeaderHeight: 42,
            onHeaderCollapseChange: { reported.append($0) }
        )
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        window.rootViewController = UIHostingController(rootView: view)
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        try await Task.sleep(for: .milliseconds(300))

        let scrollView = try XCTUnwrap(firstScrollView(in: window))
        let top = -scrollView.adjustedContentInset.top

        scrollView.setContentOffset(CGPoint(x: 0, y: top + 20), animated: false)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(reported.last, 20)

        scrollView.setContentOffset(CGPoint(x: 0, y: top + 300), animated: false)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(reported.last, 42)

        scrollView.setContentOffset(CGPoint(x: 0, y: top), animated: false)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(reported.last, 0)
    }

    private func firstScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView { return scrollView }
        return view.subviews.lazy.compactMap { self.firstScrollView(in: $0) }.first
    }
}
