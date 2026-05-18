import XCTest
@testable import Pickflow

final class OnboardingPageGradientTests: XCTestCase {
    // MARK: - 모델 자체

    func test_동일한stops와앵커는_같다고판정된다() {
        let a = OnboardingPageGradient(
            stops: [
                .init(red: 0.8, green: 0.4, blue: 0.2, opacity: 1, location: 0),
                .init(red: 0.9, green: 0.6, blue: 0.4, opacity: 1, location: 1)
            ],
            startAnchor: .top,
            endAnchor: .bottomTrailing
        )
        let b = OnboardingPageGradient(
            stops: [
                .init(red: 0.8, green: 0.4, blue: 0.2, opacity: 1, location: 0),
                .init(red: 0.9, green: 0.6, blue: 0.4, opacity: 1, location: 1)
            ],
            startAnchor: .top,
            endAnchor: .bottomTrailing
        )
        XCTAssertEqual(a, b)
    }

    func test_앵커가다르면_다르다고판정된다() {
        let stops: [OnboardingPageGradient.Stop] = [
            .init(red: 0.1, green: 0.1, blue: 0.1, opacity: 1, location: 0),
            .init(red: 0.2, green: 0.2, blue: 0.2, opacity: 1, location: 1)
        ]
        let a = OnboardingPageGradient(stops: stops, startAnchor: .top, endAnchor: .bottom)
        let b = OnboardingPageGradient(stops: stops, startAnchor: .top, endAnchor: .bottomTrailing)
        XCTAssertNotEqual(a, b)
    }

    // MARK: - defaultPages 페이지별 그라데이션

    func test_defaultPages_step0과step1의_그라데이션이_동일하다() {
        let pages = OnboardingPage.defaultPages
        XCTAssertEqual(pages[0].gradient, pages[1].gradient)
    }

    func test_defaultPages_step2와step3의_그라데이션이_다르다() {
        let pages = OnboardingPage.defaultPages
        XCTAssertNotEqual(pages[2].gradient, pages[3].gradient)
    }

    func test_defaultPages_step0과step2의_그라데이션이_다르다() {
        let pages = OnboardingPage.defaultPages
        XCTAssertNotEqual(pages[0].gradient, pages[2].gradient)
    }

    func test_defaultPages_모든페이지가_최소2개의stop을가진다() {
        for page in OnboardingPage.defaultPages {
            XCTAssertGreaterThanOrEqual(
                page.gradient.stops.count, 2,
                "page \(page.id) gradient stops count"
            )
        }
    }

    func test_defaultPages_모든페이지의_stop위치는_0과1을포함한다() {
        for page in OnboardingPage.defaultPages {
            let locations = page.gradient.stops.map(\.location)
            XCTAssertEqual(locations.first, 0, "page \(page.id) first stop location")
            XCTAssertEqual(locations.last, 1, "page \(page.id) last stop location")
        }
    }
}
