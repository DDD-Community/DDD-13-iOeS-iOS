import Foundation

extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    /// 서버 전송용 날짜 포매터. `yyyy-MM-dd`, 로컬 타임존 기준.
    static let serverDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        return formatter
    }()

    /// 서버 전송용 시간 포매터. `HH:mm`, 로컬 타임존 기준.
    static let serverTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        return formatter
    }()

    /// 공지사항 표시용 날짜 포매터. `yyyy.MM.dd`.
    static let noticeDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        return formatter
    }()

    /// 서버 날짜 문자열("yyyy-MM-dd")을 공지사항 표시 문자열("yyyy.MM.dd")로 변환. 파싱 실패 시 원문 반환.
    static func noticeDisplayDate(from raw: String) -> String {
        guard let date = serverDate.date(from: raw) else { return raw }
        return noticeDate.string(from: date)
    }

    static func pickflowDisplayTime(from time: String) -> String {
        guard let minutes = minutesFromMidnight(from: time) else {
            return time
        }

        let hour = minutes / 60
        let minute = minutes % 60
        let period = hour < 12 ? "AM" : "PM"
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%@ %d:%02d", period, displayHour, minute)
    }

    static func minutesFromMidnight(from time: String) -> Int? {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return max(0, min((24 * 60) - 1, parts[0] * 60 + parts[1]))
    }
}
