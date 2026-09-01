import SwiftUI

struct SpotHeaderSection: View {
    let spot: SpotDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SpotPublicationHeader(
                name: spot.name,
                theme: spot.theme,
                status: spot.status,
                isMySpot: spot.isMySpot,
                isUserRegistered: isUserRegistered,
                metric: metric
            )

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

    /// 관리자 큐레이션이 아닌, 다른 유저가 등록해 공개한 스팟.
    private var isUserRegistered: Bool {
        !spot.isMySpot && spot.isCurated == false
    }

    /// 추천 수는 공개된 스팟에만 붙는다.
    /// 내 스팟은 공개 상태일 때만, 타인 스팟은 애초에 공개된 것만 보이므로 항상.
    private var metric: String? {
        guard spot.isMySpot else { return "추천 \(spot.likeCount ?? 0)" }
        return spot.status == .published ? "추천 \(spot.likeCount ?? 0)" : nil
    }

}
