import Foundation

enum Tab: String, CaseIterable, Identifiable {
    case explore = "탐색"
    case saved = "저장"
    case my = "마이"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .explore:
            "map"
        case .saved:
            "bookmark"
        case .my:
            "my"
        }
    }
}
