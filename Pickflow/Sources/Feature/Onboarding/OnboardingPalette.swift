import SwiftUI

enum OnboardingPalette {
    static let bgBlendingOrange = UIAsset.Colors.sunsetOrange.swiftUIColor
  static let bgBlendingOrange2 = Color(red: 0xF6 / 255, green: 0x96 / 255, blue: 0x48 / 255)
  
  static let bgBlendingBlue1 = Color(red: 0x13 / 255, green: 0x14 / 255, blue: 0x16 / 255)
  static let bgBlendingBlue2 = Color(red: 0x1E / 255, green: 0x8A / 255, blue: 0xF6 / 255, opacity: 0.5)
  
    static let backgroundBlue = UIAsset.Colors.themeReflection.swiftUIColor
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
        case .orange: OnboardingPalette.accentOrange
        case .blue: OnboardingPalette.accentBlue
        }
    }

  var gradientColos: [Gradient.Stop] {
      switch self {
      case .orange: Gradient.Stop.onboardingOrange
      case .blue: Gradient.Stop.onboardingBlue
      }
  }
  
}

extension Gradient.Stop {
  static let onboardingOrange: [Gradient.Stop] = [
    .init(color: OnboardingPalette.bgBlendingOrange, location: 0),
    .init(color: OnboardingPalette.bgBlendingOrange2, location: 1)
  ]
  
  static let onboardingBlue: [Gradient.Stop] = [
    .init(color: OnboardingPalette.bgBlendingBlue1, location: 0),
    .init(color: OnboardingPalette.bgBlendingBlue2, location: 1)
  ]
}
