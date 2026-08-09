import SwiftUI

extension SpotTheme {
    /// 선택 상태 칩 테두리 색상. 탐색 필터 칩·온보딩 무드 칩이 공유한다.
    // TODO(Design): 햇살/야경 색상값 확정 시 교체 — 현재는 임시값.
    var accentColor: Color {
        switch self {
        case .sunlight: Color(red: 255 / 255, green: 176 / 255, blue: 32 / 255)
        case .reflection: Color(red: 30 / 255, green: 138 / 255, blue: 246 / 255)
        case .sunset: Color(red: 250 / 255, green: 97 / 255, blue: 51 / 255)
        case .nightView: Color(red: 107 / 255, green: 122 / 255, blue: 232 / 255)
        }
    }
}
