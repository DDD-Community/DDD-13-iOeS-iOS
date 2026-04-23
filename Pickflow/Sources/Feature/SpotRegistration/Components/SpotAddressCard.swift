import SwiftUI

struct SpotAddressCard: View {
    let title: String
    let address: String
    let distanceText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(.white)

                Text(address)
                    .pretendard(.body(.small()))
                    .foregroundStyle(Color.spotTertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Text(distanceText)
                    .pretendard(.label(.medium))
                    .foregroundStyle(Color(red: 0.902, green: 0.910, blue: 0.918))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.spotPillBackground, in: RoundedRectangle(cornerRadius: 4))

                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.spotPhotoCardBackground, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("선택한 장소 \(title), 주소 \(address), 거리 \(distanceText)")
    }
}
