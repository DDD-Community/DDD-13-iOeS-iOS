import SwiftUI

struct SpotHeaderSection: View {
    let spot: SpotDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(spot.name)
                .pretendard(.heading(.large))
                .foregroundStyle(.gray0)
                .lineLimit(1)

            HStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image("icTwilight", bundle: PickflowResources.bundle)
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

                if let distance = spot.distance {
                    Text(String(format: "%.1fkm", distance))
                        .pretendard(.label(.medium))
                        .foregroundStyle(.gray10)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .frame(height: 24)
                        .background(.gray90)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }
}
