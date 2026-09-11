import Foundation

/// 미확인 검수완료 히스토리 목록 응답. 승인/반려로 이미 분리돼 내려온다.
struct SpotReviewHistoryList: Decodable, Sendable, Equatable {
    let approved: [ApprovedReviewHistoryItem]
    let rejected: [RejectedReviewHistoryItem]
}

struct ApprovedReviewHistoryItem: Decodable, Sendable, Equatable {
    let historyId: Int64
    let spotId: Int64
    let reviewedAt: String
}

struct RejectedReviewHistoryItem: Decodable, Sendable, Equatable {
    let historyId: Int64
    let spotId: Int64
    let rejectReason: String?
    let rejectReasonLabel: String?
    let rejectDetail: String?
    let reviewedAt: String
}

/// 히스토리 확인(check_yn=Y) 처리 응답.
struct SpotReviewHistoryCheckResponse: Decodable, Sendable, Equatable {
    let historyId: Int64
    let checkYn: String
}
