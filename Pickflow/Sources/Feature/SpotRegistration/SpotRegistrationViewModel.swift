import Foundation

@MainActor
final class SpotRegistrationViewModel: ObservableObject {
    /// 같은 폼을 신규 등록과 반려 스팟 재신청이 함께 쓴다.
    enum Mode: Equatable {
        case create
        /// 반려된 내 스팟을 고쳐서 다시 검수 요청한다.
        case resubmit(spotId: Int64)

        var isResubmission: Bool {
            if case .resubmit = self { return true }
            return false
        }
    }

    @Published var photoData: Data?
    @Published var selectedAddress: Address?
    @Published var selectedAddressName: String?
    @Published var selectedDistanceText: String = SpotRegistrationCopy.mockDistanceText
    @Published var spotName: String = ""
    @Published var theme: SpotTheme?
    @Published var capturedDate: Date?
    @Published var capturedTime: Date?
    @Published var comment: String = ""

    @Published private(set) var isSubmitting = false
    @Published var errorMessage: String?
    @Published private(set) var registeredSpotId: SpotId?

    // MARK: - PV-40 재신청

    /// 재신청 시 이미 서버에 있는 이미지. 새로 고르지 않으면 그대로 유지된다.
    @Published private(set) var existingImageUrl: String?
    @Published private(set) var isExitConfirmPresented = false
    @Published private(set) var dismissRequested = false
    /// 재신청 제출이 끝났음을 뷰에 알린다.
    @Published private(set) var didResubmit = false

    let mode: Mode

    private let spotService: SpotServiceProtocol
    private let mySpotService: MySpotServiceProtocol
    private let calendar = Calendar.spotRegistrationGregorian

    init(
        spotService: SpotServiceProtocol,
        mySpotService: MySpotServiceProtocol = getMySpotService(),
        mode: Mode = .create
    ) {
        self.spotService = spotService
        self.mySpotService = mySpotService
        self.mode = mode
    }

    /// 반려된 스팟의 기존 입력값을 폼에 채운다.
    func prefill(from spot: SpotDetail) {
        spotName = String(spot.name.prefix(20))
        theme = spot.theme
        comment = String((spot.comment ?? "").prefix(50))
        existingImageUrl = spot.imageUrl
        selectedAddress = Address(
            id: String(spot.spotId),
            name: spot.name,
            fullAddress: spot.address ?? "",
            roadAddress: nil,
            jibunAddress: nil,
            zipCode: nil,
            city: nil,
            district: nil,
            coordinate: Coordinate(latitude: spot.latitude, longitude: spot.longitude)
        )
        selectedAddressName = spot.name
        if let recordedDate = spot.recordedDate,
           let date = DateFormatter.serverDate.date(from: recordedDate) {
            capturedDate = calendar.startOfDay(for: date)
        }
        if let recordedTime = spot.recordedTime,
           let time = DateFormatter.serverTime.date(from: recordedTime) {
            capturedTime = time
        }
    }

    // MARK: 이탈 확인

    /// 재신청 폼은 채워진 내용을 잃게 되므로 나가기 전에 한 번 묻는다.
    func backTapped() {
        if mode.isResubmission {
            isExitConfirmPresented = true
        } else {
            dismissRequested = true
        }
    }

    func cancelExit() {
        isExitConfirmPresented = false
    }

    func confirmExit() {
        isExitConfirmPresented = false
        dismissRequested = true
    }

    var isRegisterEnabled: Bool {
        hasImage
            && !spotName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && selectedAddress?.coordinate != nil
            && theme != nil
            && capturedDate != nil
            && capturedTime != nil
            && !isSubmitting
    }

    /// 재신청은 이미지를 새로 고르지 않아도 된다. 서버가 기존 이미지를 유지한다.
    private var hasImage: Bool {
        photoData != nil || existingImageUrl != nil
    }

    var spotNameCount: Int {
        spotName.count
    }

    var commentCount: Int {
        comment.count
    }

    func setPhotoData(_ data: Data?) {
        photoData = data
    }

    func applyAddressSelection(_ address: Address, distanceText: String? = nil) {
        selectedAddress = address
        selectedAddressName = address.name ?? address.fullAddress
        selectedDistanceText = distanceText ?? SpotRegistrationCopy.mockDistanceText
    }

    func setSpotName(_ value: String) {
        spotName = String(value.prefix(20))
    }

    func setComment(_ value: String) {
        comment = String(value.prefix(50))
    }

    func toggleTheme(_ newTheme: SpotTheme) {
        theme = theme == newTheme ? nil : newTheme
    }

    func setCapturedDate(_ date: Date) {
        capturedDate = calendar.startOfDay(for: min(date, Date()))

        if let capturedTime {
            self.capturedTime = clampedTime(capturedTime, for: capturedDate)
        }
    }

    func setCapturedTime(_ time: Date) {
        capturedTime = clampedTime(time, for: capturedDate)
    }

    func submit() async {
        guard isRegisterEnabled else { return }
        guard let address = selectedAddress,
              let date = capturedDate,
              let time = capturedTime else {
            return
        }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let capturedAt = Self.mergeDateAndTime(date: date, time: time)
        let trimmedName = spotName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let coordinate = address.coordinate else { return }

        do {
            switch mode {
            case .create:
                guard let photoData else { return }
                let draft = SpotRegistrationDraft(
                    photoData: photoData,
                    address: address,
                    spotName: trimmedName,
                    theme: theme,
                    capturedAt: capturedAt,
                    comment: trimmedComment.isEmpty ? nil : trimmedComment
                )
                registeredSpotId = try await spotService.registerSpot(draft: draft)
                NotificationCenter.default.post(name: .spotDidRegister, object: nil)

            case let .resubmit(spotId):
                try await resubmit(
                    spotId: spotId,
                    coordinate: coordinate,
                    name: trimmedName,
                    theme: theme,
                    capturedAt: capturedAt,
                    comment: trimmedComment.isEmpty ? nil : trimmedComment
                )
            }
        } catch let e as APIError {
            e.post()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 재신청은 새 스팟을 만들지 않는다. 기존 스팟을 수정한 뒤 다시 오픈 신청한다.
    /// 등록 API 로 만들면 새 spotId 가 생겨 반려된 원본이 중복으로 남고,
    /// 좋아요·북마크도 승계되지 않는다.
    /// - TODO(PV-40): 시안 설명의 "기존 등록 플로우와 동일" 이 API 레벨까지 뜻하는지
    ///                기획 확인 대기 중. 확인되면 이 메서드만 갈아끼우면 된다.
    private func resubmit(
        spotId: Int64,
        coordinate: Coordinate,
        name: String,
        theme: SpotTheme?,
        capturedAt: Date,
        comment: String?
    ) async throws {
        guard let theme else { return }
        let draft = MySpotUpdateDraft(
            name: name,
            theme: theme,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            comment: comment,
            capturedAt: capturedAt,
            // 새로 고르지 않았으면 서버가 기존 이미지를 유지한다.
            photoData: photoData
        )
        _ = try await mySpotService.updateMySpot(spotId: spotId, draft: draft)
        _ = try await mySpotService.requestOpen(spotId: spotId)
        didResubmit = true
        NotificationCenter.default.post(name: .spotDidRegister, object: nil)
    }

    private func clampedTime(_ time: Date, for date: Date?) -> Date {
        guard let date else {
            return min(time, Date())
        }

        let merged = Self.mergeDateAndTime(date: date, time: time)

        if calendar.isDate(date, inSameDayAs: Date()), merged > Date() {
            return Date()
        }

        return time
    }

    private static func mergeDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.spotRegistrationGregorian
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var mergedComponents = DateComponents()
        mergedComponents.year = dateComponents.year
        mergedComponents.month = dateComponents.month
        mergedComponents.day = dateComponents.day
        mergedComponents.hour = timeComponents.hour
        mergedComponents.minute = timeComponents.minute
        return calendar.date(from: mergedComponents) ?? date
    }
}
