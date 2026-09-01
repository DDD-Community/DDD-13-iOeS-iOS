import Foundation

extension Notification.Name {
    static let userProfileDidUpdate = Notification.Name("pickflow.userProfileDidUpdate")
    static let userDidSignOut = Notification.Name("pickflow.userDidSignOut")
    static let userDidWithdraw = Notification.Name("pickflow.userDidWithdraw")
    static let spotBookmarkDidChange = Notification.Name("pickflow.spotBookmarkDidChange")
    static let spotDidRegister = Notification.Name("pickflow.spotDidRegister")
    static let spotLikeDidChange = Notification.Name("pickflow.spotLikeDidChange")
}

/// `.spotLikeDidChange` 알림의 payload. 북마크와 달리 목록에서 전체를
/// 다시 불러오지 않고 해당 아이템만 갱신할 수 있도록 최종 값을 함께 보낸다.
struct SpotLikeChange: Sendable, Equatable {
    let spotId: Int64
    let likeCount: Int
    let isLiked: Bool
}
