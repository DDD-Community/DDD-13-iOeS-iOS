import SwiftUI

struct SpotListCell: View {
    let item: SpotListItem
    let isBookmarked: Bool
    let likeCount: Int?
    let onBookmarkTap: () -> Void
    var onCellTap: () -> Void = {}
    /// PV-40: 상세를 열 수 없는 저장 스팟(삭제·비공개)의 안내 문구.
    /// 값이 있으면 썸네일과 메타를 죽이고 그 위에 문구를 덮는다.
    var unavailableNotice: String? = nil

    // MARK: - PV-131 썸네일 로드 재시도
    /// AsyncImage 를 강제로 다시 만들어 재시도를 유도하는 값. 실패할 때마다 증가시킨다.
    @State private var thumbnailReloadToken = 0
    /// 무한 재시도를 막는 시도 횟수 상한.
    @State private var thumbnailRetryCount = 0
    private static let maxThumbnailRetries = 2

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            thumbnailBox
            metaRow
                .opacity(unavailableNotice == nil ? 1 : 0.28)
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
                    .opacity(unavailableNotice == nil ? 1 : 0.2)

                if let unavailableNotice {
                    Text(unavailableNotice)
                        .pretendard(.body(.small(.bold)))
                        .foregroundStyle(UIAsset.Colors.gray20.swiftUIColor)
                        .multilineTextAlignment(.center)
                        // 썸네일이 고정 크기라 큰 글씨에서 잘린다. 넘치는 대신 줄여 맞춘다.
                        .minimumScaleFactor(0.6)
                        .lineLimit(3)
                        .padding(.horizontal, 12)
                        // 위쪽 태그 행과 겹치지 않도록 세로 여백을 두고, 그래도 모자라면 글자를 줄인다.
                        .padding(.vertical, 44)
                        .frame(width: w, height: h)
                }
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
            if let url = Self.thumbnailURL(from: item.thumbnailUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: height)
                            .clipped()
                    case .failure:
                        // 네트워크 일시 오류 등으로 로드가 실패해도 조용히 회색 박스로 영구히
                        // 남던 문제(PV-131) — 짧은 간격을 두고 최대 2번까지 다시 시도한다.
                        UIAsset.Colors.gray90.swiftUIColor
                            .task {
                                guard thumbnailRetryCount < Self.maxThumbnailRetries else { return }
                                thumbnailRetryCount += 1
                                try? await Task.sleep(for: .seconds(1.5))
                                thumbnailReloadToken += 1
                            }
                    default:
                        UIAsset.Colors.gray90.swiftUIColor
                    }
                }
                .id(thumbnailReloadToken)
                .frame(width: width, height: height)
                .clipped()
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }

    /// 서버 썸네일 URL 문자열엔 공백·인코딩 안 된 특수문자가 섞여 올 수 있어
    /// `URL(string:)` 이 조용히 nil 을 반환하고 썸네일 자체가 사라지던 문제(PV-131) — 실패하면
    /// query 허용 문자셋으로 percent-encoding 한 뒤 한 번 더 시도한다.
    private static func thumbnailURL(from urlString: String?) -> URL? {
        guard let urlString, !urlString.isEmpty else { return nil }
        if let url = URL(string: urlString) { return url }
        guard let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: encoded)
    }

    /// 해석하지 못한 카테고리면 뱃지를 달지 않는다.
    @ViewBuilder
    private var moodBadge: some View {
        if let theme = item.theme {
            Image(theme.iconAssetName)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .padding(4)
                .grayBackground()
        }
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
            if let theme = item.theme {
                Text(theme.displayName)
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray10)
            }
            if let count = likeCount {
                Text("·")
                .pretendard(.body(.small()))
                    .foregroundStyle(.gray50)
                Text("추천 \(count)")
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray10)
            }
        }
    }
}

#Preview {
  let item = allItems[0]
  SpotListCell(item: item, isBookmarked: true, likeCount: 10) {
    
  }
}

let allItems: [SpotListItem] = [
    SpotListItem(spotId: 1, name: "한강 노을길", theme: .sunset,
                 thumbnailUrl: nil, distanceKm: 0.4, isBookmarked: false),
    SpotListItem(spotId: 2, name: "잠실 윤슬", theme: .reflection,
                 thumbnailUrl: nil, distanceKm: 1.2, isBookmarked: false),
    SpotListItem(spotId: 3, name: "응봉산 전망대", theme: .sunset,
                 thumbnailUrl: nil, distanceKm: 2.0, isBookmarked: false),
    SpotListItem(spotId: 4, name: "반포 무지개 분수", theme: .reflection,
                 thumbnailUrl: nil, distanceKm: 2.8, isBookmarked: false),
    SpotListItem(spotId: 5, name: "선유도 일몰 포인트", theme: .sunset,
                 thumbnailUrl: nil, distanceKm: 3.5, isBookmarked: false),
    SpotListItem(spotId: 6, name: "광나루 윤슬길", theme: .reflection,
                 thumbnailUrl: nil, distanceKm: 4.1, isBookmarked: false),
    SpotListItem(spotId: 7, name: "노들섬 노을 뷰", theme: .sunset,
                 thumbnailUrl: nil, distanceKm: 4.7, isBookmarked: false),
    SpotListItem(spotId: 8, name: "성수 한강 윤슬", theme: .reflection,
                 thumbnailUrl: nil, distanceKm: 5.3, isBookmarked: false),
    SpotListItem(spotId: 9, name: "양화대교 노을", theme: .sunset,
                 thumbnailUrl: nil, distanceKm: 6.0, isBookmarked: false),
    SpotListItem(spotId: 10, name: "동작대교 윤슬", theme: .reflection,
                 thumbnailUrl: nil, distanceKm: 6.8, isBookmarked: false),
    SpotListItem(spotId: 11, name: "성산대교 노을", theme: .sunset,
                 thumbnailUrl: nil, distanceKm: 7.4, isBookmarked: false),
    SpotListItem(spotId: 12, name: "뚝섬 윤슬 산책로", theme: .reflection,
                 thumbnailUrl: nil, distanceKm: 8.2, isBookmarked: false),
]

extension View {
  func grayBackground(_ color: UIAsset.Colors = .gray95, cornerRadius: CGFloat = 4) -> some View {
    self
      .background(color)
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    
  }
}
