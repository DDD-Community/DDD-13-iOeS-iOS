import SwiftUI

extension SpotTheme {
    /// 카테고리 대표색. 온보딩 무드 칩 테두리에 쓴다.
    ///
    /// 탐색 상단 필터 칩은 카테고리와 무관하게 선택 시 단일 주황(#FA6133)을 쓰므로
    /// 이 값을 참조하지 않는다 — 디자인 확인 완료.
    /// 햇살/야경은 각 아이콘의 벡터 색을 그대로 따른다.
    var accentColor: Color {
        switch self {
        case .sunlight: Color(red: 255 / 255, green: 161 / 255, blue: 0 / 255)
        case .reflection: Color(red: 30 / 255, green: 138 / 255, blue: 246 / 255)
        case .sunset: Color(red: 250 / 255, green: 97 / 255, blue: 51 / 255)
        case .nightView: Color(red: 230 / 255, green: 232 / 255, blue: 234 / 255)
        }
    }
}
