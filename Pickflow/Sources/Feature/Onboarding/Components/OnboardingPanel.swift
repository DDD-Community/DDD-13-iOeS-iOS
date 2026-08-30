import SwiftUI

struct OnboardingPanel: View {
    let page: OnboardingPage
    let currentIndex: Int
    let pageCount: Int
    let primaryButtonTitle: String
    let onPrimaryTap: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 16) {
                titleText
                Text(page.subtitle)
                .pretendard(.body(.medium()))
                    .foregroundStyle(OnboardingPalette.subtitle)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            OnboardingPageIndicator(
                count: pageCount,
                currentIndex: currentIndex
            )

            OnboardingPrimaryButton(title: primaryButtonTitle, action: onPrimaryTap)
        }
        .padding(.top, 36)
        .padding(.bottom, 28)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(OnboardingPalette.panelBackground)
    }

    private var titleText: some View {
        Text(makeTitleAttributedString())
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func makeTitleAttributedString() -> AttributedString {
        var attributed = AttributedString(page.title)
      let style: PretendardStyle = .heading(.large)
      attributed.font = style.token.font
        attributed.foregroundColor = OnboardingPalette.title
        for highlight in page.titleHighlights {
            if let range = attributed.range(of: highlight) {
                attributed[range].foregroundColor = page.theme.accentColor
            }
        }
        return attributed
    }
}
