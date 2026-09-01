import Foundation

/// 나만의 스팟 수정 응답. 수정으로 상태는 바뀌지 않는다.
struct UpdateMySpotResponse: Decodable, Sendable, Equatable {
    let spotId: Int64
    let status: MySpotStatus?
    let imageUrl: String?
}

/// 오픈 신청 응답. `status` 는 PENDING 또는 RE_REVIEW_PENDING.
struct OpenMySpotResponse: Decodable, Sendable, Equatable {
    let spotId: Int64
    let status: MySpotStatus?
}

/// 공개 해제 응답.
/// `previousStatus` 로 오픈 신청 철회(PENDING/RE_REVIEW_PENDING)였는지
/// 비공개 전환(PUBLISHED)이었는지 구분한다. `status` 는 항상 DRAFT.
struct CancelPublicationResponse: Decodable, Sendable, Equatable {
    let spotId: Int64
    let previousStatus: MySpotStatus?
    let status: MySpotStatus?

    /// 검수 결과를 기다리던 신청을 유저가 스스로 거둬들인 경우.
    var wasWithdrawnFromReview: Bool {
        previousStatus?.isUnderReview == true
    }
}

/// 추천(좋아요) 등록/취소 응답.
/// `likeCount` 는 서버에 최종 반영된 값이므로 화면은 이 값 기준으로 맞춘다.
struct SpotLikeResponse: Decodable, Sendable, Equatable {
    let likeCount: Int
    let isLiked: Bool
}
