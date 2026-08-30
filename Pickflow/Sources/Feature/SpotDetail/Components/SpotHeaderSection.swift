import SwiftUI

struct SpotHeaderSection: View {
    let spot: SpotDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 내 스팟만 PV-40 헤더(상태 뱃지 + 추천 수)를 쓴다.
            // 타인/큐레이션 스팟 상세는 시안을 아직 못 받아 기존 표기를 그대로 둔다.
            if spot.isMySpot {
                SpotPublicationHeader(
                    name: spot.name,
                    theme: spot.theme,
                    status: spot.status,
                    isMySpot: true,
                    metric: metric
                )
            } else {
                otherSpotHeader
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

    /// 공개된 내 스팟만 추천 수를 보여준다. 나만보기·검수중·반려엔 지표가 없다.
    private var metric: String? {
        spot.status == .published ? "추천 \(spot.likeCount ?? 0)" : nil
    }

    private var otherSpotHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(spot.name)
                .pretendard(.heading(.large))
                .foregroundStyle(.gray0)

            // 해석하지 못한 카테고리면 표기를 빼고 북마크 수만 남긴다.
            if let subtitle {
                Text(subtitle)
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray30)
            }
        }
    }

    private var subtitle: String? {
        let theme = spot.theme?.displayName
        let bookmark = "북마크 \(spot.bookmarkCount)"
        return [theme, bookmark].compactMap { $0 }.joined(separator: " · ")
    }
}
