import Foundation

/// 내가 등록한 스팟의 생명주기(수정/삭제/오픈신청/공개해제)를 다룬다. (PV-40)
protocol MySpotServiceProtocol: Sendable {
    /// 나만보기(DRAFT) 또는 반려(REJECTED) 상태의 스팟을 수정한다.
    /// 검수중이거나 공개된 스팟은 서버가 SP010으로 거절하므로 공개를 먼저 해제해야 한다.
    func updateMySpot(spotId: Int64, draft: MySpotUpdateDraft) async throws -> UpdateMySpotResponse

    /// 스팟을 삭제(논리삭제)한다. 검수중이면 서버가 SP011로 거절한다.
    func deleteMySpot(spotId: Int64) async throws

    /// 오픈 신청(검수 요청).
    @discardableResult
    func requestOpen(spotId: Int64) async throws -> OpenMySpotResponse

    /// 공개 해제. 검수중이면 신청 철회, 공개중이면 비공개 전환으로 처리된다.
    @discardableResult
    func cancelPublication(spotId: Int64) async throws -> CancelPublicationResponse
}

/// 스팟 수정 요청 값. 전달한 값으로 전체를 덮어쓴다.
/// `photoData` 가 nil 이면 기존 이미지를 그대로 유지한다.
struct MySpotUpdateDraft: Sendable, Equatable {
    let name: String
    let theme: SpotTheme
    let latitude: Double
    let longitude: Double
    let comment: String?
    let capturedAt: Date?
    let photoData: Data?
}

@MainActor
func getMySpotService() -> MySpotServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(MySpotServiceProtocol.self) else {
        fatalError("MySpotServiceProtocol is not registered in DIContainer")
    }
    return service
}
