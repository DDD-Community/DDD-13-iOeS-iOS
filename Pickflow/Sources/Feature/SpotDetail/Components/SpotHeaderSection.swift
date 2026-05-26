import SwiftUI

struct SpotHeaderSection: View {
    let spot: SpotDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 6) {
                Text(spot.name)
                    .pretendard(.heading(.large))
                    .foregroundStyle(.gray0)
                if spot.isMySpot {
                    Text("MY 스팟")
                        .pretendard(.body(.small(.bold)))
                        .foregroundStyle(.sunsetOrange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                          RoundedRectangle(cornerRadius: 4)
                            .fill(.clear)
                            .stroke(UIAsset.Colors.sunsetOrange.color, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            Text(spot.isMySpot ? spot.theme.rawValue : "\(spot.theme.rawValue) · 북마크 \(spot.bookmarkCount)")
                .pretendard(.body(.small()))
                .foregroundStyle(.gray30)

            Text(spot.comment)
                .pretendard(.body(.medium()))
                .foregroundStyle(.gray0)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(.gray90)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
