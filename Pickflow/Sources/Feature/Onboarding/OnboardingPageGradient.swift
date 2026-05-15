import CoreGraphics
import SwiftUI

struct OnboardingPageGradient: Hashable, Sendable {
    struct Stop: Hashable, Sendable {
        let red: Double
        let green: Double
        let blue: Double
        let opacity: Double
        let location: CGFloat
    }

    enum Anchor: Hashable, Sendable {
        case top
        case bottom
        case leading
        case trailing
        case topLeading
        case topTrailing
        case bottomLeading
        case bottomTrailing
        case center
    }

    let stops: [Stop]
    let startAnchor: Anchor
    let endAnchor: Anchor
}

extension OnboardingPageGradient.Stop {
  init(hex: UInt32, opacity: Double = 1.0, location: CGFloat) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b, opacity: opacity, location: location)
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

extension OnboardingPageGradient.Anchor {
    var unitPoint: UnitPoint {
        switch self {
        case .top: .top
        case .bottom: .bottom
        case .leading: .leading
        case .trailing: .trailing
        case .topLeading: .topLeading
        case .topTrailing: .topTrailing
        case .bottomLeading: .bottomLeading
        case .bottomTrailing: .bottomTrailing
        case .center: .center
        }
    }
}

extension OnboardingPageGradient {
    var linearGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(stops: stops.map { stop in
                Gradient.Stop(color: stop.color, location: stop.location)
            }),
            startPoint: startAnchor.unitPoint,
            endPoint: endAnchor.unitPoint
        )
    }
}
