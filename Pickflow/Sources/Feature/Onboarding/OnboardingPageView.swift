import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage
    let currentIndex: Int
    let pageCount: Int
    let onPrimaryTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OnboardingIllustration(page: page)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            OnboardingPanel(
                page: page,
                currentIndex: currentIndex,
                pageCount: pageCount,
                onPrimaryTap: onPrimaryTap
            )
        }
        .background(OnboardingPalette.panelBackground)
    }
}
