import Foundation

private struct SpotRegisterRequest: Encodable, Sendable {
    let name: String
    let theme: String?
    let latitude: Double
    let longitude: Double
    let comment: String?
    let recordedDate: String
    let recordedTime: String
}

enum SpotRegistrationError: LocalizedError {
    case missingCoordinate

    var errorDescription: String? {
        switch self {
        case .missingCoordinate:
            "선택한 장소의 좌표를 가져올 수 없습니다."
        }
    }
}

final class SpotService: SpotServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func fetchSpotDetail(id: Int64, latitude _: Double?, longitude _: Double?) async throws -> SpotDetail {
        let envelope: APIEnvelope<SpotDetail> = try await networkManager.request(
            endpoint: SpotEndpoint.detail(spotId: id)
        )
        return envelope.data
    }

    func fetchSpotPreview(id: Int64, latitude: Double?, longitude: Double?) async throws -> SpotPreviewResponse {
        let envelope: APIEnvelope<SpotPreviewResponse> = try await networkManager.request(
            endpoint: SpotPreviewEndpoint(spotId: id, latitude: latitude, longitude: longitude)
        )
        return envelope.data
    }


    func registerSpot(draft: SpotRegistrationDraft) async throws -> SpotId {
        guard let coordinate = draft.address.coordinate else {
            throw SpotRegistrationError.missingCoordinate
        }

        let request = SpotRegisterRequest(
            name: draft.spotName,
            theme: draft.theme?.apiCode,
            latitude: coordinate.latitude.roundedTo6,
            longitude: coordinate.longitude.roundedTo6,
            comment: draft.comment,
            recordedDate: DateFormatter.serverDate.string(from: draft.capturedAt),
            recordedTime: DateFormatter.serverTime.string(from: draft.capturedAt)
        )
        let requestJSON = try JSONEncoder().encode(request)
        let photoData = draft.photoData

        let envelope: APIEnvelope<SpotRegisterResponse> = try await networkManager.upload(
            endpoint: SpotEndpoint.register
        ) { formData in
            formData.append(
                requestJSON,
                withName: "request",
                mimeType: "application/json"
            )
            formData.append(
                photoData,
                withName: "image",
                fileName: "spot.jpg",
                mimeType: "image/jpeg"
            )
        }
        return SpotId(rawValue: String(envelope.data.spotId))
    }

    func reportSpot(id: Int64, content: String) async throws {
        let _: EmptyResponse = try await networkManager.request(
            endpoint: ReportEndpoint(spotId: id, content: content)
        )
    }

    func likeSpot(id: Int64) async throws -> SpotLikeResponse {
        let envelope: APIEnvelope<SpotLikeResponse> = try await networkManager.request(
            endpoint: SpotLikeEndpoint.like(spotId: id)
        )
        return envelope.data
    }

    func unlikeSpot(id: Int64) async throws -> SpotLikeResponse {
        let envelope: APIEnvelope<SpotLikeResponse> = try await networkManager.request(
            endpoint: SpotLikeEndpoint.unlike(spotId: id)
        )
        return envelope.data
    }
}

private extension Double {
    var roundedTo6: Double {
        (self * 1_000_000).rounded() / 1_000_000
    }
}
