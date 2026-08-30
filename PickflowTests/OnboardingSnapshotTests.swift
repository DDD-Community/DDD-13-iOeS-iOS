import SnapshotTesting
import SwiftUI
import XCTest
@testable import Pickflow

@MainActor
final class OnboardingSnapshotTests: XCTestCase {

    private let pages = OnboardingPage.defaultPages

    // MARK: - Full screen (Page 0~3, Light/Dark)

    func test_onboarding_screen_page0_light() {
        assertScreenSnapshot(at: 0, style: .light, named: "onboarding-screen-page0-light")
    }

    func test_onboarding_screen_page0_dark() {
        assertScreenSnapshot(at: 0, style: .dark, named: "onboarding-screen-page0-dark")
    }

    func test_onboarding_screen_page1_light() {
        assertScreenSnapshot(at: 1, style: .light, named: "onboarding-screen-page1-light")
    }

    func test_onboarding_screen_page1_dark() {
        assertScreenSnapshot(at: 1, style: .dark, named: "onboarding-screen-page1-dark")
    }

    func test_onboarding_screen_page2_light() {
        assertScreenSnapshot(at: 2, style: .light, named: "onboarding-screen-page2-light")
    }

    func test_onboarding_screen_page2_dark() {
        assertScreenSnapshot(at: 2, style: .dark, named: "onboarding-screen-page2-dark")
    }

    func test_onboarding_screen_page3_light() {
        assertScreenSnapshot(at: 3, style: .light, named: "onboarding-screen-page3-light")
    }

    func test_onboarding_screen_page3_dark() {
        assertScreenSnapshot(at: 3, style: .dark, named: "onboarding-screen-page3-dark")
    }

    // MARK: - Page indicator (4 active positions, always orange accent)

    func test_onboarding_indicator_page0_light() {
        assertIndicatorSnapshot(currentIndex: 0, named: "onboarding-indicator-page0-light")
    }

    func test_onboarding_indicator_page1_light() {
        assertIndicatorSnapshot(currentIndex: 1, named: "onboarding-indicator-page1-light")
    }

    func test_onboarding_indicator_page2_light() {
        assertIndicatorSnapshot(currentIndex: 2, named: "onboarding-indicator-page2-light")
    }

    func test_onboarding_indicator_page3_light() {
        assertIndicatorSnapshot(currentIndex: 3, named: "onboarding-indicator-page3-light")
    }

    // MARK: - Bottom panel (text highlight color verification)

    func test_onboarding_panel_page0_light() {
        assertPanelSnapshot(at: 0, style: .light, named: "onboarding-panel-page0-light")
    }

    func test_onboarding_panel_page0_dark() {
        assertPanelSnapshot(at: 0, style: .dark, named: "onboarding-panel-page0-dark")
    }

    func test_onboarding_panel_page3_light() {
        assertPanelSnapshot(at: 3, style: .light, named: "onboarding-panel-page3-light")
    }

    func test_onboarding_panel_page3_dark() {
        assertPanelSnapshot(at: 3, style: .dark, named: "onboarding-panel-page3-dark")
    }

    // MARK: - CTA

    func test_onboarding_cta_light() {
        let view = OnboardingPrimaryButton(title: "시작하기", action: {})
            .padding(.horizontal, 20)
            .background(OnboardingPalette.panelBackground)
            .frame(width: 393, height: 96)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 393, height: 96),
                traits: UITraitCollection(userInterfaceStyle: .light)
            ),
            named: "onboarding-cta-light"
        )
    }

    func test_onboarding_cta_dark() {
        let view = OnboardingPrimaryButton(title: "시작하기", action: {})
            .padding(.horizontal, 20)
            .background(OnboardingPalette.panelBackground)
            .frame(width: 393, height: 96)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 393, height: 96),
                traits: UITraitCollection(userInterfaceStyle: .dark)
            ),
            named: "onboarding-cta-dark"
        )
    }

    // MARK: - Accessibility (DynamicType .accessibilityExtraLarge)

    func test_onboarding_screen_page0_a11y() {
        assertScreenSnapshot(
            at: 0,
            style: .light,
            contentSize: .accessibilityExtraLarge,
            named: "onboarding-screen-page0-a11y"
        )
    }

    func test_onboarding_screen_page3_a11y() {
        assertScreenSnapshot(
            at: 3,
            style: .light,
            contentSize: .accessibilityExtraLarge,
            named: "onboarding-screen-page3-a11y"
        )
    }

    // MARK: - Illustration component (KAN-106)

    func test_onboarding_illustration_step0_light() {
        assertIllustrationSnapshot(at: 0, style: .light, named: "onboarding-illustration-step0-light")
    }

    func test_onboarding_illustration_step0_dark() {
        assertIllustrationSnapshot(at: 0, style: .dark, named: "onboarding-illustration-step0-dark")
    }

    func test_onboarding_illustration_step1_light() {
        assertIllustrationSnapshot(at: 1, style: .light, named: "onboarding-illustration-step1-light")
    }

    func test_onboarding_illustration_step1_dark() {
        assertIllustrationSnapshot(at: 1, style: .dark, named: "onboarding-illustration-step1-dark")
    }

    func test_onboarding_illustration_step2_light() {
        assertIllustrationSnapshot(at: 2, style: .light, named: "onboarding-illustration-step2-light")
    }

    func test_onboarding_illustration_step2_dark() {
        assertIllustrationSnapshot(at: 2, style: .dark, named: "onboarding-illustration-step2-dark")
    }

    func test_onboarding_illustration_step3_light() {
        assertIllustrationSnapshot(at: 3, style: .light, named: "onboarding-illustration-step3-light")
    }

    func test_onboarding_illustration_step3_dark() {
        assertIllustrationSnapshot(at: 3, style: .dark, named: "onboarding-illustration-step3-dark")
    }

    private func assertIllustrationSnapshot(
        at index: Int,
        style: UIUserInterfaceStyle,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = OnboardingIllustration(
            page: pages[index],
            isCarouselAnimating: false
        )
        .frame(width: 393, height: 600)

        let traits = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: style),
            UITraitCollection(preferredContentSizeCategory: .large)
        ])
        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 393, height: 600),
                traits: traits
            ),
            named: name,
            file: file,
            line: line
        )
    }

    // MARK: - Production OnboardingView regression

    func test_onboardingView_page0_light() {
        assertOnboardingViewSnapshot(at: 0, style: .light, named: "onboardingView-page0-light")
    }

    func test_onboardingView_page3_light() {
        assertOnboardingViewSnapshot(at: 3, style: .light, named: "onboardingView-page3-light")
    }

    private func assertOnboardingViewSnapshot(
        at index: Int,
        style: UIUserInterfaceStyle,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let viewModel = OnboardingViewModel(
            pages: pages,
            completionStore: MockOnboardingCompletionStore()
        )
        viewModel.setPage(index)
        let view = OnboardingView(
            viewModel: viewModel,
            isCarouselAnimating: false
        )

        let traits = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: style),
            UITraitCollection(preferredContentSizeCategory: .large)
        ])
        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: .iPhone13Pro), traits: traits),
            named: name,
            file: file,
            line: line
        )
    }

    // MARK: - Helpers

    private func assertScreenSnapshot(
        at index: Int,
        style: UIUserInterfaceStyle,
        contentSize: UIContentSizeCategory = .large,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let page = pages[index]
        let view = VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                OnboardingIllustration(
                    page: page,
                    isCarouselAnimating: false
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                PickflowWorkMarkLogo()
                    .padding(.leading, 16)
                    .padding(.top, 12)
            }

            OnboardingPanel(
                page: page,
                currentIndex: index,
                pageCount: pages.count,
                primaryButtonTitle: index == pages.count - 1 ? "시작하기" : "다음으로",
                onPrimaryTap: {}
            )
        }
        .background(OnboardingPalette.panelBackground)

        let traits = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: style),
            UITraitCollection(preferredContentSizeCategory: contentSize)
        ])
        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: .iPhone13Pro), traits: traits),
            named: name,
            file: file,
            line: line
        )
    }

    private func assertPanelSnapshot(
        at index: Int,
        style: UIUserInterfaceStyle,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = OnboardingPanel(
            page: pages[index],
            currentIndex: index,
            pageCount: pages.count,
            primaryButtonTitle: index == pages.count - 1 ? "시작하기" : "다음으로",
            onPrimaryTap: {}
        )
        .frame(width: 393)
        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 393, height: 320),
                traits: UITraitCollection(userInterfaceStyle: style)
            ),
            named: name,
            file: file,
            line: line
        )
    }

    private func assertIndicatorSnapshot(
        currentIndex: Int,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = OnboardingPageIndicator(
            count: pages.count,
            currentIndex: currentIndex
        )
        .padding(20)
        .background(OnboardingPalette.panelBackground)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 160, height: 60),
                traits: UITraitCollection(userInterfaceStyle: .light)
            ),
            named: name,
            file: file,
            line: line
        )
    }
}
