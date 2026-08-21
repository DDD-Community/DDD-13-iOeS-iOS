import SwiftUI

/// 나만의 스팟 탭용 카드. 북마크 액션은 없고, 상단 좌측에 검수/공개/반려 상태 뱃지를 노출한다.
struct MySpotListCell: View {
    let item: MySpotListItem
    var onCellTap: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            thumbnailBox
            metaRow
        }
        .contentShape(Rectangle())
        .onTapGesture { onCellTap() }
    }

    private var thumbnailBox: some View {
        let aspect: CGFloat = item.spotId.isMultiple(of: 2) ? 1.2 : 0.9
        return GeometryReader { proxy in
            let w = proxy.size.width
            let h = w * aspect
            ZStack(alignment: .top) {
                thumbnail(width: w, height: h)
                HStack(alignment: .top) {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            moodBadge
                            if let distanceKm = item.distanceKm {
                                distanceBadge(distanceKm)
                            }
                        }
                        statusBadge
                    }
                }
                .padding(8)
            }
            .frame(width: w, height: h)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .aspectRatio(1.0 / aspect, contentMode: .fit)
    }

    @ViewBuilder
    private func thumbnail(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            UIAsset.Colors.gray90.swiftUIColor
            if let urlString = item.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: height)
                            .clipped()
                    default:
                        UIAsset.Colors.gray90.swiftUIColor
                    }
                }
                .frame(width: width, height: height)
                .clipped()
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }

    private var aspect: CGFloat { item.spotId.isMultiple(of: 2) ? 1.2 : 0.9 }

    /// 나만보기(DRAFT)와 알 수 없는 상태는 뱃지를 달지 않는다.
    @ViewBuilder
    private var statusBadge: some View {
        if let badgeText = item.status.badgeText {
            Text(badgeText)
                .pretendard(.label(.medium))
                .foregroundStyle(.gray0)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusBackground)
                .clipShape(Capsule())
        }
    }

    private var statusBackground: Color {
        switch item.status {
        case .pending, .reReviewPending: UIAsset.Colors.gray80.swiftUIColor.opacity(0.85)
        case .published: UIAsset.Colors.sunsetOrange.swiftUIColor.opacity(0.85)
        case .rejected: Color.red.opacity(0.7)
        case .draft, .unknown: .clear
        }
    }

    private var moodBadge: some View {
        Image(item.theme.iconAssetName)
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .padding(4)
            .grayBackground()
    }

    private func distanceBadge(_ km: Double) -> some View {
        Text(String(format: "%.1fkm", km))
            .pretendard(.label(.medium))
            .foregroundStyle(.gray10)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .grayBackground()
    }

    private var metaRow: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.name)
                .pretendard(.body(.small(.bold)))
                .foregroundStyle(.gray0)
                .lineLimit(1)
                .truncationMode(.tail)

            HStack(spacing: 6) {
                Text("북마크 \(item.bookmarkCount)")
                    .pretendard(.label(.medium))
                    .foregroundStyle(.gray30)
            }
        }
    }
}
