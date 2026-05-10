import SwiftUI

struct SpotSearchResultItem: View {
    let address: Address
    let distanceText: String?
    let action: () -> Void

    private var title: String {
        address.name ?? address.fullAddress
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(UIAsset.Colors.gray0.color)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(address.fullAddress)
                        .pretendard(.body(.small()))
                        .foregroundStyle(UIAsset.Colors.gray30.color)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let distanceText {
                    Text(distanceText)
                        .pretendard(.label(.medium))
                        .tracking(0.2)
                        .foregroundStyle(UIAsset.Colors.gray10.color)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(UIAsset.Colors.gray90.color, in: RoundedRectangle(cornerRadius: 4))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
