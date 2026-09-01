import Foundation

private struct UpdateMySpotRequest: Encodable, Sendable {
    let name: String
    let theme: String
    let latitude: Double
    let longitude: Double
    let comment: String?
    let recordedDate: String?
    let recordedTime: String?
}

final class MySpotService: MySpotServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func updateMySpot(spotId: Int64, draft: MySpotUpdateDraft) async throws -> UpdateMySpotResponse {
        let request = UpdateMySpotRequest(
            name: draft.name,
            theme: draft.theme.apiCode,
            latitude: draft.latitude.roundedTo6,
            longitude: draft.longitude.roundedTo6,
            comment: draft.comment,
            recordedDate: draft.capturedAt.map { DateFormatter.serverDate.string(from: $0) },
            recordedTime: draft.capturedAt.map { DateFormatter.serverTime.string(from: $0) }
        )
        let requestJSON = try JSONEncoder().encode(request)
        let photoData = draft.photoData

        let envelope: APIEnvelope<UpdateMySpotResponse> = try await networkManager.upload(
            endpoint: MySpotEndpoint.update(spotId: spotId)
        ) { formData in
            formData.append(
                requestJSON,
                withName: "request",
                mimeType: "application/json"
            )
            // 이미지를 첨부하지 않으면 서버가 기존 이미지를 유지한다.
            if let photoData {
                formData.append(
                    photoData,
                    withName: "image",
                    fileName: "spot.jpg",
                    mimeType: "image/jpeg"
                )
            }
        }
        return envelope.data
    }

    func deleteMySpot(spotId: Int64) async throws {
        let _: EmptyResponse = try await networkManager.request(
            endpoint: MySpotEndpoint.delete(spotId: spotId)
        )
    }

    @discardableResult
    func requestOpen(spotId: Int64) async throws -> OpenMySpotResponse {
        let envelope: APIEnvelope<OpenMySpotResponse> = try await networkManager.request(
            endpoint: MySpotEndpoint.requestOpen(spotId: spotId)
        )
        return envelope.data
    }

    @discardableResult
    func cancelPublication(spotId: Int64) async throws -> CancelPublicationResponse {
        let envelope: APIEnvelope<CancelPublicationResponse> = try await networkManager.request(
            endpoint: MySpotEndpoint.cancelPublication(spotId: spotId)
        )
        return envelope.data
    }
}

private extension Double {
    var roundedTo6: Double {
        (self * 1_000_000).rounded() / 1_000_000
    }
}
