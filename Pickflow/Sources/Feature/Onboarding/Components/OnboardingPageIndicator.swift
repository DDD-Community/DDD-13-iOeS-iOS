import SwiftUI

struct OnboardingPageIndicator: View {
    let count: Int
    let currentIndex: Int
    let activeColor: Color = OnboardingPalette.accentOrange

    private let dotSize: CGFloat = 8
    private let activeWidth: CGFloat = 20
    private let spacing: CGFloat = 8

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? activeColor : OnboardingPalette.indicatorInactive)
                    .frame(
                        width: index == currentIndex ? activeWidth : dotSize,
                        height: dotSize
                    )
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: currentIndex)
    }
}
