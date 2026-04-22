import SwiftUI

struct SpotAddressCard: View {
    let title: String
    let address: String
    let distanceText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(.white)

                    Text(address)
                        .pretendard(.body(.small()))
                        .foregroundStyle(Color.spotSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Text(distanceText)
                    .pretendard(.label(.small))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.spotPillBackground, in: Capsule())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.spotCardBackground, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("선택한 장소 \(title), 주소 \(address), 거리 \(distanceText)")
    }
}
