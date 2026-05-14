import SwiftUI

struct OnboardingPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(OnboardingPalette.title)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(OnboardingPalette.accentOrange)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
