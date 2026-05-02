import SwiftUI

struct HeroCard: View {
    let eyebrow: String
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(eyebrow)
                .pretendard(.label(.small))
                .foregroundStyle(.gray50)

            Text(title)
                .pretendard(.display(.medium))
                .foregroundStyle(.gray95)

            Text(description)
                .pretendard(.body(.medium()))
                .foregroundStyle(.gray60)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(.gray0)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(.gray10, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 16, x: 0, y: 6)
    }
}
