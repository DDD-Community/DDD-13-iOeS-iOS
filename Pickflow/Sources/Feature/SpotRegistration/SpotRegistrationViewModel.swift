import Foundation

@MainActor
final class SpotRegistrationViewModel: ObservableObject {
    @Published var photoData: Data?
    @Published var selectedAddress: Address?
    @Published var selectedAddressName: String?
    @Published var selectedDistanceText: String = SpotRegistrationCopy.mockDistanceText
    @Published var spotName: String = ""
    @Published var category: PhotoCategory?
    @Published var capturedDate: Date?
    @Published var capturedTime: Date?
    @Published var comment: String = ""

    @Published private(set) var isSubmitting = false
    @Published var errorMessage: String?
    @Published private(set) var registeredSpotId: SpotId?

    private let spotService: SpotServiceProtocol
    private let calendar = Calendar.spotRegistrationGregorian

    init(spotService: SpotServiceProtocol) {
        self.spotService = spotService
    }

    var isRegisterEnabled: Bool {
        photoData != nil
            && !spotName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && selectedAddress != nil
            && capturedDate != nil
            && capturedTime != nil
            && !isSubmitting
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

    func applyMockAddressSelection() {
        selectedAddress = .mockSpotRegistrationAddress
        selectedAddressName = SpotRegistrationCopy.mockPlaceName
        selectedDistanceText = SpotRegistrationCopy.mockDistanceText
    }

    func setSpotName(_ value: String) {
        spotName = String(value.prefix(20))
    }

    func setComment(_ value: String) {
        comment = String(value.prefix(50))
    }

    func toggleCategory(_ newCategory: PhotoCategory) {
        category = category == newCategory ? nil : newCategory
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
        guard let photoData,
              let address = selectedAddress,
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

        let draft = SpotRegistrationDraft(
            photoData: photoData,
            address: address,
            spotName: trimmedName,
            category: category,
            capturedAt: capturedAt,
            comment: trimmedComment.isEmpty ? nil : trimmedComment
        )

        do {
            registeredSpotId = try await spotService.registerSpot(draft: draft)
        } catch {
            errorMessage = error.localizedDescription
        }
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
