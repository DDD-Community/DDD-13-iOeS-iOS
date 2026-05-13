import Foundation

enum SpotDetailAnalyticsEvent: AnalyticsEvent {
    case shareButtonTap

    var name: String {
        switch self {
        case .shareButtonTap: "spot_detail_share_btn_tap"
        }
    }
}
