import SwiftUI

struct SpotListCell: View {
    let item: SpotListItem
    let isBookmarked: Bool
    let bookmarkCount: Int?
    let onBookmarkTap: () -> Void
    var onCellTap: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            thumbnailBox
            metaRow
        }
        .contentShape(Rectangle())
        .onTapGesture { onCellTap() }
    }

    // MARK: - Thumbnail

    private var thumbnailBox: some View {
        // height:width 비율(aspect>1 이면 세로로 더 김). Masonry 효과를 위해 짝/홀 분기.
        // 핵심: GeometryReader 로 부모가 주는 width 를 잠그고 height = width * aspect 로 강제.
        // AsyncImage 의 intrinsic size 가 layout cascade 를 흔드는 것을 막는다.
        let aspect: CGFloat = item.spotId.isMultiple(of: 2) ? 1.2 : 0.9
        return GeometryReader { proxy in
            let w = proxy.size.width
            let h = w * aspect
            ZStack(alignment: .top) {
                thumbnail(width: w, height: h)
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
            .frame(width: w, height: h)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .aspectRatio(1.0 / aspect, contentMode: .fit)
    }

    @ViewBuilder
    private func thumbnail(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            UIAsset.Colors.gray90.swiftUIColor
            if let urlString = item.thumbnailUrl, let url = URL(string: urlString) {
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

    private var moodBadge: some View {
        Image(item.theme.overlayAssetName)
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

    // MARK: - Meta (썸네일 외부)

    private var metaRow: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .pretendard(.body(.small(.bold)))
                    .foregroundStyle(.gray0)
                    .lineLimit(1)
                    .truncationMode(.tail)

                subtitleRow
            }

            Spacer(minLength: 0)

            Button(action: onBookmarkTap) {
                Image(isBookmarked ? .icBookmarkFilled : .icBookmarkBorder)
                .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 18)
                    .scaleEffect(1.4)
                    .padding(10)
                    .foregroundStyle(isBookmarked ? .gray0 : .gray30)
                    
                    
            }
            .buttonStyle(.plain)
        }
    }

    private var subtitleRow: some View {
        HStack(spacing: 4) {
            Text(item.theme.displayName)
                .pretendard(.body(.small()))
                .foregroundStyle(.gray10)
            if let count = bookmarkCount {
                Text("·")
                .pretendard(.body(.small()))
                    .foregroundStyle(.gray50)
                Text("북마크 \(count)")
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray10)
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
        case .sunset: "icon_photo_category_sunset"
        case .reflection: "icon_photo_category_reflection"
        }
    }
}

#Preview {
  let item = allItems[0]
  SpotListCell(item: item, isBookmarked: true, bookmarkCount: 10) {
    
  }
}

let allItems: [SpotListItem] = [
    SpotListItem(spotId: 1, name: "한강 노을길", theme: .sunset,
                 thumbnailUrl: nil, distanceKm: 0.4),
    SpotListItem(spotId: 2, name: "잠실 윤슬", theme: .reflection,
                 thumbnailUrl: nil, distanceKm: 1.2),
    SpotListItem(spotId: 3, name: "응봉산 전망대", theme: .sunset,
                 thumbnailUrl: nil, distanceKm: 2.0),
    SpotListItem(spotId: 4, name: "반포 무지개 분수", theme: .reflection,
                 thumbnailUrl: nil, distanceKm: 2.8),
    SpotListItem(spotId: 5, name: "선유도 일몰 포인트", theme: .sunset,
                 thumbnailUrl: nil, distanceKm: 3.5),
    SpotListItem(spotId: 6, name: "광나루 윤슬길", theme: .reflection,
                 thumbnailUrl: nil, distanceKm: 4.1),
    SpotListItem(spotId: 7, name: "노들섬 노을 뷰", theme: .sunset,
                 thumbnailUrl: nil, distanceKm: 4.7),
    SpotListItem(spotId: 8, name: "성수 한강 윤슬", theme: .reflection,
                 thumbnailUrl: nil, distanceKm: 5.3),
    SpotListItem(spotId: 9, name: "양화대교 노을", theme: .sunset,
                 thumbnailUrl: nil, distanceKm: 6.0),
    SpotListItem(spotId: 10, name: "동작대교 윤슬", theme: .reflection,
                 thumbnailUrl: nil, distanceKm: 6.8),
    SpotListItem(spotId: 11, name: "성산대교 노을", theme: .sunset,
                 thumbnailUrl: nil, distanceKm: 7.4),
    SpotListItem(spotId: 12, name: "뚝섬 윤슬 산책로", theme: .reflection,
                 thumbnailUrl: nil, distanceKm: 8.2),
]

extension View {
  func grayBackground(_ color: UIAsset.Colors = .gray95, cornerRadius: CGFloat = 4) -> some View {
    self
      .background(color)
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    
  }
}
