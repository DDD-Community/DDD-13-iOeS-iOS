import UIKit
import XCTest
@testable import Pickflow

/// 켰는데 조용히 아무 일도 안 일어나는 경로(씬을 못 찾음)를 잡는다.
@MainActor
final class TouchIndicatorPresenterTests: XCTestCase {

    override func tearDown() {
        TouchIndicatorPresenter.shared.setEnabled(false)
        super.tearDown()
    }

    func test_켜면_오버레이가붙는다() {
        TouchIndicatorPresenter.shared.setEnabled(true)

        XCTAssertTrue(TouchIndicatorPresenter.shared.isAttached)
    }

    func test_끄면_오버레이가떨어진다() {
        TouchIndicatorPresenter.shared.setEnabled(true)

        TouchIndicatorPresenter.shared.setEnabled(false)

        XCTAssertFalse(TouchIndicatorPresenter.shared.isAttached)
    }

    /// 두 번 켜도 오버레이가 겹쳐 쌓이지 않아야 한다.
    func test_여러번켜도_오버레이는하나다() {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let before = scene?.windows.count ?? 0

        TouchIndicatorPresenter.shared.setEnabled(true)
        TouchIndicatorPresenter.shared.setEnabled(true)
        TouchIndicatorPresenter.shared.setEnabled(true)

        let after = scene?.windows.count ?? 0
        XCTAssertEqual(after, before + 1)
    }

    /// 오버레이는 터치를 통과시켜야 한다. 막으면 앱이 먹통이 된다.
    func test_오버레이는_터치를통과시킨다() {
        TouchIndicatorPresenter.shared.setEnabled(true)

        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let overlay = scene?.windows.first { $0.windowLevel > .alert }

        XCTAssertNotNil(overlay)
        XCTAssertNil(overlay?.hitTest(CGPoint(x: 100, y: 100), with: nil))
        XCTAssertFalse(overlay?.isUserInteractionEnabled ?? true)
    }
}
