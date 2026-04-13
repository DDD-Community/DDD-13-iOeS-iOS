import SwiftUI
import UIKit

enum PretendardFontName {
    static let regular = "Pretendard-Regular"
    static let medium = "Pretendard-Medium"
    static let semiBold = "Pretendard-SemiBold"
    static let bold = "Pretendard-Bold"
}

enum PretendardWeight {
    case regular
    case medium
    case semiBold
    case bold

    var fallbackWeight: SwiftUI.Font.Weight {
        switch self {
        case .regular:
            .regular
        case .medium:
            .medium
        case .semiBold:
            .semibold
        case .bold:
            .bold
        }
    }

    var fontName: String {
        switch self {
        case .regular:
            PretendardFontName.regular
        case .medium:
            PretendardFontName.medium
        case .semiBold:
            PretendardFontName.semiBold
        case .bold:
            PretendardFontName.bold
        }
    }
}

struct PretendardToken {
    let size: CGFloat
    let lineHeight: CGFloat
    let kerning: CGFloat
    let weight: PretendardWeight

    var lineSpacing: CGFloat {
        max(0, lineHeight - size)
    }

    var font: SwiftUI.Font {
        if UIFont(name: weight.fontName, size: size) != nil {
            return .custom(weight.fontName, size: size)
        }

        return .system(size: size, weight: weight.fallbackWeight)
    }
}

enum PretendardStyle: Hashable {
    enum Display: String, CaseIterable {
        case large = "large"
        case medium = "medium"
    }

    enum Heading: String, CaseIterable {
        case large = "large"
        case medium = "medium"
        case small = "small"
    }

    enum BodyWeight: String, CaseIterable {
        case regular = "regular"
        case bold = "bold"
    }

    enum Body: Hashable {
        case large(BodyWeight = .regular)
        case medium(BodyWeight = .regular)
        case small(BodyWeight = .regular)

        var sizeName: String {
            switch self {
            case .large:
                "large"
            case .medium:
                "medium"
            case .small:
                "small"
            }
        }

        var weight: BodyWeight {
            switch self {
            case let .large(weight), let .medium(weight), let .small(weight):
                weight
            }
        }
    }

    enum Label: String, CaseIterable {
        case medium = "medium"
        case small = "small"
        case xsmall = "xsmall"
    }

    case display(Display)
    case heading(Heading)
    case body(Body)
    case label(Label)

    static let allCases: [PretendardStyle] = [
        .display(.large),
        .display(.medium),
        .heading(.large),
        .heading(.medium),
        .heading(.small),
        .body(.large()),
        .body(.large(.bold)),
        .body(.medium()),
        .body(.medium(.bold)),
        .body(.small()),
        .body(.small(.bold)),
        .label(.medium),
        .label(.small),
        .label(.xsmall),
    ]

    var token: PretendardToken {
        switch self {
        case .display(.large):
            PretendardToken(size: 34, lineHeight: 40.8, kerning: -0.2, weight: .bold)
        case .display(.medium):
            PretendardToken(size: 28, lineHeight: 33.6, kerning: -0.2, weight: .bold)
        case .heading(.large):
            PretendardToken(size: 24, lineHeight: 28.8, kerning: 0, weight: .semiBold)
        case .heading(.medium):
            PretendardToken(size: 22, lineHeight: 26.4, kerning: 0, weight: .semiBold)
        case .heading(.small):
            PretendardToken(size: 19, lineHeight: 22.8, kerning: 0, weight: .semiBold)
        case .body(.large(.regular)):
            PretendardToken(size: 17, lineHeight: 23.8, kerning: 0, weight: .regular)
        case .body(.large(.bold)):
            PretendardToken(size: 17, lineHeight: 23.8, kerning: 0, weight: .semiBold)
        case .body(.medium(.regular)):
            PretendardToken(size: 15, lineHeight: 21, kerning: 0, weight: .regular)
        case .body(.medium(.bold)):
            PretendardToken(size: 15, lineHeight: 21, kerning: 0, weight: .semiBold)
        case .body(.small(.regular)):
            PretendardToken(size: 13, lineHeight: 16.9, kerning: 0, weight: .regular)
        case .body(.small(.bold)):
            PretendardToken(size: 13, lineHeight: 16.9, kerning: 0, weight: .semiBold)
        case .label(.medium):
            PretendardToken(size: 13, lineHeight: 15.6, kerning: 0, weight: .medium)
        case .label(.small):
            PretendardToken(size: 12, lineHeight: 14.4, kerning: 0.2, weight: .medium)
        case .label(.xsmall):
            PretendardToken(size: 11, lineHeight: 13.2, kerning: 0.2, weight: .medium)
        }
    }
}

struct PretendardTypographyModifier: ViewModifier {
    let style: PretendardStyle

    func body(content: Content) -> some View {
        let token = style.token

        content
            .font(token.font)
            .tracking(token.kerning)
            .lineSpacing(token.lineSpacing)
    }
}

extension View {
    func pretendard(_ style: PretendardStyle) -> some View {
        modifier(PretendardTypographyModifier(style: style))
    }
}
