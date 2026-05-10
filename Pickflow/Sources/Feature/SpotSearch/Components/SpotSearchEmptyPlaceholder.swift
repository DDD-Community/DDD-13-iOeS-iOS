import SwiftUI

struct SpotSearchEmptyPlaceholder: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            AssetImage(named: "ic_flare", renderingMode: .template, size: 28) {
                Image(systemName: "sparkle")
                    .font(.system(size: 24, weight: .medium))
                    .frame(width: 28, height: 28)
            }
            .foregroundStyle(UIAsset.Colors.gray60.color)

            Text(message)
                .pretendard(.body(.large(.bold)))
                .foregroundStyle(UIAsset.Colors.gray60.color)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 200)
        .accessibilityElement(children: .combine)
    }
}
