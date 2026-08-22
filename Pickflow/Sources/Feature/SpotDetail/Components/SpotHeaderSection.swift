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

            // 해석하지 못한 카테고리면 표기를 빼고 북마크 수만 남긴다.
            if let subtitle = subtitle {
                Text(subtitle)
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray30)
            }

            // 코멘트는 등록 시 선택 항목이라 없을 수 있다. 없으면 빈 말풍선을 띄우지 않는다.
            if let comment = spot.comment, !comment.isEmpty {
                Text(comment)
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

    /// 내 스팟은 카테고리만, 남의 스팟은 카테고리 · 북마크 수.
    /// 카테고리를 해석하지 못했으면 그 부분만 빠진다.
    private var subtitle: String? {
        let theme = spot.theme?.displayName
        guard !spot.isMySpot else { return theme }
        let bookmark = "북마크 \(spot.bookmarkCount)"
        return [theme, bookmark].compactMap { $0 }.joined(separator: " · ")
    }
}
