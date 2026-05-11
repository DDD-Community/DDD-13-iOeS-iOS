import SwiftUI

struct OnboardingPanel: View {
    let page: OnboardingPage
    let currentIndex: Int
    let pageCount: Int
    let onPrimaryTap: () -> Void
    var onSwipeNext: () -> Void = {}
    var onSwipePrevious: () -> Void = {}

    private let swipeThreshold: CGFloat = 50
    private let swipeMinimumDistance: CGFloat = 24

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

            OnboardingPrimaryButton(title: "시작하기", action: onPrimaryTap)
        }
        .padding(.top, 36)
        .padding(.bottom, 28)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(OnboardingPalette.panelBackground)
        .contentShape(Rectangle())
        .gesture(swipeGesture)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: swipeMinimumDistance)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = abs(value.translation.height)
                // 수평 우세 제스처만 페이지 이동으로 해석. 세로 드래그·짧은 탭은 무시.
                guard abs(horizontal) > vertical else { return }
                if horizontal < -swipeThreshold {
                    onSwipeNext()
                } else if horizontal > swipeThreshold {
                    onSwipePrevious()
                }
            }
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
        if let highlight = page.titleHighlight,
           let range = attributed.range(of: highlight) {
            attributed[range].foregroundColor = page.theme.accentColor
        }
        return attributed
    }
}
