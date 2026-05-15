import Foundation

enum ShareFakedoorAnalyticsEvent: AnalyticsEvent {
    case notifyButtonTap

    var name: String {
        switch self {
        case .notifyButtonTap: "modal_share_fakedoor_btn_tap"
        }
    }
}
