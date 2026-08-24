import SwiftUI

/// PV-40 시안에만 등장해 디자인 시스템 팔레트에 없는 색.
/// 팔레트에 편입되면 이 확장을 지우고 UIAsset 쪽으로 옮긴다.
extension Color {
    /// 스팟 타이틀 (#F4F4F1). gray5(#F4F5F6)와 미세하게 달라 시안 값을 그대로 쓴다.
    static let spotPublicationTitle = Color(red: 244 / 255, green: 244 / 255, blue: 241 / 255)
    /// "스팟 삭제하기" 링크 (#E14B21)
    static let spotDeleteLink = Color(red: 225 / 255, green: 75 / 255, blue: 33 / 255)
    /// 반려 배너 위에 얹는 붉은 오버레이 (#B83311, 12%)
    static let spotRejectionOverlay = Color(red: 184 / 255, green: 51 / 255, blue: 17 / 255)
}
