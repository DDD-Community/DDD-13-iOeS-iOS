import Foundation

enum AppReviewAnalyticsEvent: AnalyticsEvent {
    /// 최초 스팟 등록 완료 후 앱스토어 평점 요청 시스템 팝업을 발동(노출 요청)한 시점.
    case systemPromptShown

    var name: String {
        switch self {
        case .systemPromptShown: "app_review_system_prompt_shown"
        }
    }
}
