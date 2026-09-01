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

/// `.spotBookmarkDidChange` 알림에 실려오는 선택적 payload.
/// 보관함/마이페이지는 페이로드 없이(object: nil) 전체를 조용히 다시 불러오는 방식을
/// 그대로 쓰지만(북마크는 목록에서 아이템이 사라지고 나타나는 경우가 있어 필드 갱신만으론
/// 부족하다), 탐색 리스트는 아이템이 그대로 남아 있으므로 해당 아이템만 갱신하면 된다.
struct SpotBookmarkChange: Sendable, Equatable {
    let spotId: Int64
    let isBookmarked: Bool
}
