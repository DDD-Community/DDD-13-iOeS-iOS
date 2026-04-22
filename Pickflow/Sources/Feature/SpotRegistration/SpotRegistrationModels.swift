import SwiftUI

enum SpotRegistrationCopy {
    static let mockPlaceName = "잠원 한강공원"
    static let mockDistanceText = "2.5km"
}

extension PhotoCategory {
    var iconEmoji: String {
        switch self {
        case .sunset:
            "🌇"
        case .reflection:
            "🌊"
        }
    }

    var displayName: String {
        switch self {
        case .sunset:
            "노을"
        case .reflection:
            "윤슬"
        }
    }
}

extension Address {
    static let mockSpotRegistrationAddress = Address(
        id: "mock-jamwon",
        fullAddress: "서울 서초구 잠원로 221-124 잠원한강공원",
        roadAddress: "서울 서초구 잠원로 221-124 잠원한강공원",
        jibunAddress: nil,
        zipCode: nil,
        city: "서울",
        district: "서초구",
        coordinate: Coordinate(latitude: 37.5209, longitude: 127.0116)
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
    static let spotSecondaryText = Color(red: 0.541, green: 0.541, blue: 0.557)
    static let spotOrange = Color(red: 1.000, green: 0.416, blue: 0.165)
    static let spotDisabled = Color(red: 0.353, green: 0.353, blue: 0.353)
    static let spotChipBorder = Color(red: 0.267, green: 0.267, blue: 0.282)
    static let spotDivider = Color.white.opacity(0.08)
    static let spotPillBackground = Color.white.opacity(0.08)
}
