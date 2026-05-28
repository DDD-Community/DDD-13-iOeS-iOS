import SwiftUI

enum SpotRegistrationCopy {
    static let mockPlaceName = "잠원 한강공원"
    static let mockDistanceText = "2.5km"
}

extension SpotTheme {
    var iconAssetName: String {
        switch self {
        case .sunset:
            "icon_photo_category_sunset"
        case .reflection:
            "icon_photo_category_reflection"
        }
    }

    var iconEmoji: String {
        switch self {
        case .sunset:
            "🌇"
        case .reflection:
            "🌊"
        }
    }
}

extension Address {
    static let mockSpotRegistrationAddress = Address(
        id: "mock-cityhall",
        name: SpotRegistrationCopy.mockPlaceName,
        fullAddress: "서울 중구 세종대로 110 서울시청",
        roadAddress: "서울 중구 세종대로 110",
        jibunAddress: nil,
        zipCode: nil,
        city: "서울",
        district: "중구",
        coordinate: Coordinate(latitude: 37.5665, longitude: 126.9780)
    )
}

extension Calendar {
    static let spotRegistrationGregorian: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.timeZone = .current
        return calendar
    }()
}

extension Locale {
    static let korean = Locale(identifier: "ko_KR")
}

extension DateFormatter {
    static let spotCaptureDateDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .korean
        formatter.calendar = .spotRegistrationGregorian
        formatter.dateFormat = "M월 d일 EEE"
        return formatter
    }()

    static let spotCaptureTimeDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .korean
        formatter.calendar = .spotRegistrationGregorian
        formatter.dateFormat = "a h:mm"
        return formatter
    }()
}

extension Color {
    static let spotBackground = Color(red: 0.043, green: 0.043, blue: 0.043)
    static let spotCardBackground = Color(red: 0.110, green: 0.110, blue: 0.118)
    static let spotPhotoCardBackground = Color(red: 0.200, green: 0.212, blue: 0.239)
    static let spotInputBackground = Color(red: 0.118, green: 0.129, blue: 0.141)
    static let spotSecondaryText = Color(red: 0.541, green: 0.541, blue: 0.557)
    static let spotTertiaryText = Color(red: 0.694, green: 0.722, blue: 0.745)
    static let spotPlaceholderText = Color(red: 0.427, green: 0.471, blue: 0.510)
    static let spotOrange = Color(red: 0.980, green: 0.380, blue: 0.200)
    static let spotDisabled = Color(red: 0.353, green: 0.353, blue: 0.353)
    static let spotChipBorder = Color(red: 0.267, green: 0.267, blue: 0.282)
    static let spotDivider = Color.white.opacity(0.08)
    static let spotPillBackground = Color(red: 0.118, green: 0.129, blue: 0.141)
}
