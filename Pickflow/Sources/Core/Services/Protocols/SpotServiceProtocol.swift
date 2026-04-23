import Foundation

protocol SpotServiceProtocol: Sendable {
    /// 스팟을 서버에 등록한다.
    /// - TODO(BE-API): 요청/응답 스키마 확정 시 draft를 실제 DTO로 매핑한다.
    /// - TODO(BE-API): 이미지 업로드 방식(multipart vs presigned URL)을 반영한다.
    func registerSpot(draft: SpotRegistrationDraft) async throws -> SpotId
}

struct SpotRegistrationDraft: Sendable {
    let photoData: Data
    let address: Address
    let spotName: String
    let category: PhotoCategory?
    let capturedAt: Date
    let comment: String?
}

struct SpotId: Hashable, Sendable, Identifiable {
    let rawValue: String

    var id: String { rawValue }
}

enum PhotoCategory: String, CaseIterable, Sendable, Hashable {
    case sunset
    case reflection
}

@MainActor
func getSpotService() -> SpotServiceProtocol {
    guard let service = DIContainerHolder.shared?.resolve(SpotServiceProtocol.self) else {
        fatalError("SpotServiceProtocol is not registered in DIContainer")
    }
    return service
}
