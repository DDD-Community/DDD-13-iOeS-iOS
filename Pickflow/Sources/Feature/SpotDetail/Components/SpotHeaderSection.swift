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
                legacyHeader
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

    /// 공개된 내 스팟만 추천 수를 보여준다. 나만보기·검수중·반려엔 지표가 없다.
    private var metric: String? {
        spot.status == .published ? "추천 \(spot.likeCount ?? 0)" : nil
    }

    private var legacyHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(spot.name)
                .pretendard(.heading(.large))
                .foregroundStyle(.gray0)
            Text("\(spot.theme.rawValue) · 북마크 \(spot.bookmarkCount)")
                .pretendard(.body(.small()))
                .foregroundStyle(.gray30)
        }
    }
}
