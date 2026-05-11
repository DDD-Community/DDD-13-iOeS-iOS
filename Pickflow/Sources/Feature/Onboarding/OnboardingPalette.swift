import SwiftUI

enum OnboardingPalette {
    static let panelBackground = UIAsset.Colors.gray95.swiftUIColor
    static let accentOrange = UIAsset.Colors.sunsetOrange.swiftUIColor
    static let accentBlue = Color(red: 0x1E / 255, green: 0x8A / 255, blue: 0xF6 / 255)
    static let title = UIAsset.Colors.gray0.swiftUIColor
    static let subtitle = UIAsset.Colors.gray20.swiftUIColor
    static let indicatorInactive = UIAsset.Colors.gray70.swiftUIColor
}

extension OnboardingPage.AccentTheme {
    var accentColor: Color {
        switch self {
        case .orange, .darkOrange: OnboardingPalette.accentOrange
        case .blue: OnboardingPalette.accentBlue
        }
    }
  
}

