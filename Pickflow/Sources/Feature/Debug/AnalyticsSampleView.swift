// [KAN-91] PR 머지 시 삭제 예정 — GA 로깅 동작 검증용 임시 샘플 화면
#if DEBUG
import SwiftUI

struct AnalyticsSampleView: View {
    private let logger: AnalyticsLoggerProtocol
    @State private var lastSent: String?

    init(logger: AnalyticsLoggerProtocol = getAnalyticsLogger()) {
        self.logger = logger
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Analytics Sample")
                .font(.title2.bold())

            Button("공유하기 버튼 (spot_detail_share_btn_tap)") {
                logger.log(SpotDetailAnalyticsEvent.shareButtonTap)
                lastSent = SpotDetailAnalyticsEvent.shareButtonTap.name
            }
            .buttonStyle(.borderedProminent)

            Button("알림 받을게요 (modal_share_fakedoor_btn_tap)") {
                logger.log(ShareFakedoorAnalyticsEvent.notifyButtonTap)
                lastSent = ShareFakedoorAnalyticsEvent.notifyButtonTap.name
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)

            if let lastSent {
                Text("마지막 전송: \(lastSent)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
#endif
