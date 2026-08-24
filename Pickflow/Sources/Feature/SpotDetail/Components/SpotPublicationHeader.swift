import SwiftUI

/// 스팟 타이틀 + 상태 뱃지 + 서브타이틀(테마 · 지표).
/// 지표는 공개된 내 스팟이면 "추천 N", 타인/큐레이션 스팟이면 "북마크 N",
/// 비공개 상태의 내 스팟이면 없다.
struct SpotPublicationHeader: View {
    let name: String
    let theme: SpotTheme
    let status: MySpotStatus?
    let isMySpot: Bool
    let metric: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(name)
                    .pretendard(.heading(.large))
                    .foregroundStyle(Color.spotPublicationTitle)
                if let badge = SpotStatusBadge(status: status, isMySpot: isMySpot) {
                    badge
                }
            }
            subtitle
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subtitle: some View {
        HStack(spacing: 4) {
            Text(theme.displayName)
                .pretendard(.body(.medium()))
                .foregroundStyle(UIAsset.Colors.gray30.swiftUIColor)
            if let metric {
                Circle()
                    .fill(UIAsset.Colors.gray30.swiftUIColor)
                    .frame(width: 2, height: 2)
                // 축약 표기 없이 원 숫자 그대로 노출한다(기획 3.8).
                Text(metric)
                    .pretendard(.body(.medium()))
                    .foregroundStyle(UIAsset.Colors.gray30.swiftUIColor)
            }
        }
    }
}
