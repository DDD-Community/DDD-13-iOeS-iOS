import Foundation

final class SpotService: SpotServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func registerSpot(draft: SpotRegistrationDraft) async throws -> SpotId {
        _ = networkManager
        // TODO(BE-API): 실제 네트워크 호출로 교체
        // TODO(BE-API): 이미지 업로드, 카테고리 enum 키, 응답 스키마 확정 필요
        try await Task.sleep(for: .seconds(1))
        return SpotId(rawValue: UUID().uuidString)
    }
}
