import Foundation

protocol SpotServiceProtocol: Sendable {
    func fetchSpotDetail(id: Int64, latitude: Double?, longitude: Double?) async throws -> SpotDetail
    func fetchSpotPreview(id: Int64, latitude: Double?, longitude: Double?) async throws -> SpotPreviewResponse
    /// 스팟을 서버에 등록한다.
    /// - TODO(BE-API): 요청/응답 스키마 확정 시 draft를 실제 DTO로 매핑한다.
    /// - TODO(BE-API): 이미지 업로드 방식(multipart vs presigned URL)을 반영한다.
    func registerSpot(draft: SpotRegistrationDraft) async throws -> SpotId
    func reportSpot(id: Int64, content: String) async throws

    /// 스팟에 추천(좋아요)을 등록한다. 공개된 스팟에만 허용된다. (PV-40)
    /// - Returns: 서버에 최종 반영된 추천 수와 내 추천 여부.
    func likeSpot(id: Int64) async throws -> SpotLikeResponse

    /// 등록한 추천을 취소한다. (PV-40)
    func unlikeSpot(id: Int64) async throws -> SpotLikeResponse
}

struct SpotRegistrationDraft: Sendable {
    let photoData: Data
    let address: Address
    let spotName: String
    let theme: SpotTheme?
    let capturedAt: Date
    let comment: String?
}

struct SpotId: Hashable, Sendable, Identifiable {
    let rawValue: String

    var id: String { rawValue }
}

@MainActor
func getSpotService() -> SpotServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(SpotServiceProtocol.self) else {
        fatalError("SpotServiceProtocol is not registered in DIContainer")
    }
    return service
}
