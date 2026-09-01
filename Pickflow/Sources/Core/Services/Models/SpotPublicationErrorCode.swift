import Foundation

/// PV-40 유저 스팟 공개 시스템에서 서버가 내려주는 도메인 에러 코드.
/// 호출부가 `APIError.code` 문자열을 직접 비교하지 않도록 모아둔다.
enum SpotPublicationErrorCode: String, Sendable, Equatable, CaseIterable {
    /// 존재하지 않거나 비공개인 스팟. 비공개는 403이 아니라 404로 내려온다.
    case spotNotFound = "SP001"
    /// 철회 직전에 운영자가 검수를 확정한 경합 상황.
    case alreadyReviewed = "SP004"
    /// 오픈 신청할 수 없는 상태.
    case notOpenable = "SP005"
    /// 본인이 등록한 스팟이 아님.
    case notOwner = "SP008"
    /// 해제할 대상이 없는 상태(이미 나만보기).
    case nothingToCancel = "SP009"
    /// 검수중이거나 공개된 스팟이라 수정 불가.
    case notEditable = "SP010"
    /// 검수 중인 스팟이라 삭제 불가.
    case notDeletable = "SP011"
    /// 이미 추천한 스팟.
    case alreadyLiked = "SL001"
    /// 추천하지 않은 스팟.
    case notLiked = "SL002"
    /// 추천할 수 없는 상태의 스팟(비공개 유저 스팟).
    case notLikeable = "SL003"
    /// 인증 필요 — 토큰 없음/만료/블랙리스트.
    case unauthorized = "C004"

    /// 사용자에게 그대로 보여줄 수 있는 안내 문구.
    /// 서버 `message` 가 있으면 그쪽이 우선이고, 이건 폴백이다.
    var userMessage: String {
        switch self {
        case .spotNotFound: "삭제되었거나 볼 수 없는 스팟이에요."
        case .alreadyReviewed: "이미 처리된 신청이에요."
        case .notOpenable: "지금은 오픈 신청할 수 없어요."
        case .notOwner: "내가 등록한 스팟만 관리할 수 있어요."
        case .nothingToCancel: "이미 나만 볼 수 있는 상태예요."
        case .notEditable: "공개를 먼저 해제한 뒤 수정할 수 있어요."
        case .notDeletable: "오픈 신청을 먼저 철회한 뒤 삭제할 수 있어요."
        case .alreadyLiked, .notLiked: "잠시 후 다시 시도해주세요."
        case .notLikeable: "공개된 스팟에만 추천할 수 있어요."
        case .unauthorized: "로그인이 필요해요."
        }
    }
}

extension Error {
    /// 이 에러가 PV-40 도메인 에러라면 해당 코드를, 아니면 nil 을 돌려준다.
    var spotPublicationErrorCode: SpotPublicationErrorCode? {
        guard let apiError = self as? APIError else { return nil }
        return SpotPublicationErrorCode(rawValue: apiError.code)
    }
}
