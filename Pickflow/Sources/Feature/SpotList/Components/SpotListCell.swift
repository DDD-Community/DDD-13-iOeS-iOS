import SwiftUI

struct SpotListCell: View {
    let item: SpotListItem
    let isBookmarked: Bool
    let bookmarkCount: Int?
    let onBookmarkTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            thumbnailBox
            metaRow
        }
    }

    // MARK: - Thumbnail

    private var thumbnailBox: some View {
        let aspect: CGFloat = item.spotId.isMultiple(of: 2) ? 1.2 : 0.9
        return ZStack(alignment: .top) {
            thumbnail
                .aspectRatio(1.0 / aspect, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(alignment: .center) {
                Spacer()
                HStack(spacing: 4) {
                    moodBadge
                    if let distanceKm = item.distanceKm {
                        distanceBadge(distanceKm)
                    }
                }
            }
            .padding(8)
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        ZStack {
            UIAsset.Colors.gray90.swiftUIColor
            if let urlString = item.thumbnailUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image.resizable().scaledToFill()
                    default:
                        UIAsset.Colors.gray90.swiftUIColor
                    }
                }
            }
        }
    }

    private var moodBadge: some View {
        // FIXME(Figma 908:19343): 자산 자체에 배경/아이콘이 포함된 색채 이미지. 사이즈는 Figma 측정값으로 교체.
        Image(item.theme.overlayAssetName)
            .resizable()
            .scaledToFit()
            .frame(width: 32, height: 32)
    }

    private func distanceBadge(_ km: Double) -> some View {
        Text(String(format: "%.1fkm", km))
            .pretendard(.body(.medium(.bold)))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            // FIXME(Figma 908:19343): 거리 박스 배경/투명도 토큰 확정 전 gray100 사용
            .background(UIAsset.Colors.gray100.swiftUIColor.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Meta (썸네일 외부)

    private var metaRow: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                subtitleRow
            }

            Spacer(minLength: 0)

            Button(action: onBookmarkTap) {
                Image(isBookmarked ? .icBookmarkFilled : .icBookmarkBorder)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(isBookmarked
                        ? UIAsset.Colors.sunsetOrange.swiftUIColor
                        : .white)
            }
            .buttonStyle(.plain)
        }
    }

    private var subtitleRow: some View {
        HStack(spacing: 6) {
            Text(item.theme.displayName)
                .pretendard(.body(.small()))
                .foregroundStyle(.gray40)
            if let count = bookmarkCount {
                Text("·")
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray40)
                Text("북마크 \(count)")
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray40)
            }
        }
    }
}

extension SpotTheme {
    var displayName: String {
        switch self {
        case .sunset: "노을"
        case .reflection: "윤슬"
        }
    }

    var overlayAssetName: String {
        switch self {
        case .sunset: "sunset"
        case .reflection: "sparklingRipple"
        }
    }
}
