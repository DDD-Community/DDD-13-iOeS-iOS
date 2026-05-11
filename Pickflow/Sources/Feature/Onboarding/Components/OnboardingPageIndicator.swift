import SwiftUI

struct OnboardingPageIndicator: View {
    let count: Int
    let currentIndex: Int
    let activeColor: Color = OnboardingPalette.accentOrange

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                if index == currentIndex {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(activeColor)
                        .frame(width: 20, height: 8)
                } else {
                    Circle()
                        .fill(OnboardingPalette.indicatorInactive)
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
}
