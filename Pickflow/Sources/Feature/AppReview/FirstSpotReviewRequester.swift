import Foundation

/// 최초 스팟 등록 성공 시, 앱스토어 평점 요청 시스템 팝업을 1회에 한해 발동한다.
///
/// 정책(기획):
/// - 스팟 등록 "성공" 시점에만 발동한다(등록 실패 시 호출되지 않아야 한다).
/// - 팝업을 한 번 발동했다면 이후 등록에서는 다시 발동하지 않는다(앱 내부 1회 제어).
/// - 팝업의 실제 노출 여부/횟수는 iOS 시스템이 결정한다(연 3회 제한 등).
@MainActor
protocol FirstSpotReviewRequesterProtocol {
    /// 스팟 등록이 성공적으로 완료되고 완료 UI가 정리된 직후 호출한다.
    func spotRegistrationDidComplete()
}

@MainActor
final class FirstSpotReviewRequester: FirstSpotReviewRequesterProtocol {
    private let store: ReviewRequestStore
    private let service: ReviewRequestServiceProtocol
    private let analyticsLogger: AnalyticsLoggerProtocol
    /// 등록 화면 dismiss 애니메이션이 정리된 뒤 팝업이 뜨도록 하는 지연(초).
    private let presentDelay: Double

    init(
        store: ReviewRequestStore = getReviewRequestStore(),
        service: ReviewRequestServiceProtocol = getReviewRequestService(),
        analyticsLogger: AnalyticsLoggerProtocol = getAnalyticsLogger(),
        presentDelay: Double = 0.4
    ) {
        self.store = store
        self.service = service
        self.analyticsLogger = analyticsLogger
        self.presentDelay = presentDelay
    }

    func spotRegistrationDidComplete() {
        // 이미 한 번 발동한 이력이 있으면 즉시 종료(2번째 등록부터 미노출).
        guard !store.hasRequestedReview() else { return }

        Task { @MainActor in
            await requestReviewAfterDelay()
        }
    }

    /// dismiss 애니메이션이 정리되도록 지연한 뒤 실제 요청을 발동한다.
    /// 발동 성공 시에만 1회 처리 플래그와 노출 로그를 남긴다.
    func requestReviewAfterDelay() async {
        if presentDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(presentDelay * 1_000_000_000))
        }

        // 활성 window scene을 찾아 실제로 요청을 발동한 경우에만 1회 처리로 확정한다.
        // scene을 찾지 못해 발동하지 못했다면 플래그를 남기지 않아 다음 기회에 재시도한다.
        guard service.requestReview() else { return }

        store.markReviewRequested()
        analyticsLogger.log(AppReviewAnalyticsEvent.systemPromptShown)
    }
}

@MainActor
func getFirstSpotReviewRequester() -> FirstSpotReviewRequesterProtocol {
    FirstSpotReviewRequester()
}
