import SwiftUI

struct SpotHeaderSection: View {
    let spot: SpotDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 6) {
                Text(spot.name)
                    .pretendard(.heading(.large))
                    .foregroundStyle(.gray0)
                if spot.isMine {
                    Text("MY 스팟")
                        .pretendard(.label(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.sunsetOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            HStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(spot.theme.chipIconAssetName, bundle: PickflowResources.bundle)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text(spot.theme.rawValue)
                        .pretendard(.body(.small(.bold)))
                }
                .foregroundStyle(.gray10)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(height: 24)
                .background(.gray90)
                .clipShape(RoundedRectangle(cornerRadius: 4))

                if !spot.isMine {
                    Text("·")
                        .pretendard(.body(.small()))
                        .foregroundStyle(.gray30)
                    Text("북마크 \(spot.bookmarkCount)")
                        .pretendard(.body(.small()))
                        .foregroundStyle(.gray30)
                }
            }

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

private extension SpotTheme {
    var chipIconAssetName: String {
        switch self {
        case .sunset: "icon_photo_category_sunset"
        case .reflection: "icon_photo_category_reflection"
        }
    }
}
