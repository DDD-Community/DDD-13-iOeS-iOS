import Foundation

enum WithdrawalReason: String, CaseIterable, Codable, Sendable, Identifiable {
    case insufficientSpots
    case difficultToUse
    case rarelyUsed
    case bugsOrIssues
    case newAccount
    case privacyConcerns
    case other

    var id: String { rawValue }

    var displayText: String {
        switch self {
        case .insufficientSpots: "원하는 스팟이 부족해요"
        case .difficultToUse:   "앱 사용이 어려워요"
        case .rarelyUsed:       "자주 사용하지 않아요"
        case .bugsOrIssues:     "오류나 불편함이 있어요"
        case .newAccount:       "새 계정을 만들고 싶어요"
        case .privacyConcerns:  "개인정보가 걱정돼요"
        case .other:            "기타"
        }
    }
}
