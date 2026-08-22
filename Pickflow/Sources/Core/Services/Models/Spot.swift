import Foundation

struct SpotDetail: Codable, Sendable, Identifiable, Equatable {
    let spotId: Int64
    let name: String
    let comment: String
    let theme: SpotTheme
    let latitude: Double
    let longitude: Double
    let address: String
    let imageUrl: String?
    let recordedDate: String?
    let recordedTime: String?
    let weatherSky: WeatherSky?
    let precipitation: Precipitation?
    let precipitationProbability: Int?
    let congestionLevel: CongestionLevel?
    let sunsetTime: String?
    let astronomyDate: String?
    let weatherUpdatedAt: String?
    let congestionUpdatedAt: String?
    let parkingInfo: String?
    let bookmarkCount: Int
    let isBookmarked: Bool
    let isMySpot: Bool

    // MARK: - PV-40 유저 스팟 공개 시스템
    // 서버가 아직 안 내려주거나 비로그인이면 nil 이므로 옵셔널로 둔다.

    /// 유저 등록 스팟의 공개 상태. 큐레이션 스팟이면 nil.
    var status: MySpotStatus?
    /// 관리자 큐레이션 스팟 여부. 유저 등록 스팟이면 false.
    var isCurated: Bool?
    /// 추천(좋아요) 수.
    var likeCount: Int?
    /// 내가 추천했는지. 비로그인 시 false.
    var isLiked: Bool?
    /// 추천 가능 여부. 비공개 상태의 유저 스팟이면 false.
    var isLikeable: Bool?
    /// 반려된 내 스팟일 때만 채워진다. 타인에게는 내려가지 않는다.
    var rejection: SpotRejectionInfo?

    var id: Int64 { spotId }

    /// 현재 날씨 표시용 — 강수가 있으면 강수 종류, 없으면 하늘 상태.
    var weatherDisplayName: String? {
        if let precipitation, precipitation != .none {
            return precipitation.displayName
        }
        return weatherSky?.displayName
    }
}

enum SpotTheme: String, Sendable, Equatable, CaseIterable {
    case sunlight = "햇살"
    case reflection = "윤슬"
    case sunset = "노을"
    case nightView = "야경"
}

extension SpotTheme: Codable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let code = try container.decode(String.self)
        guard let theme = SpotTheme(apiCode: code) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown SpotTheme apiCode: \(code)"
            )
        }
        self = theme
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(apiCode)
    }
}

extension SpotTheme {
    var apiCode: String {
        switch self {
        case .sunlight: "SUNLIGHT"
        case .reflection: "YUNSEUL"
        case .sunset: "SUNSET"
        case .nightView: "NIGHT_VIEW"
        }
    }

    /// 서버는 상세/미리보기에서 긴 코드(`SUNSET`), 리스트에서 짧은 코드(`SS`)를 섞어 내려준다.
    init?(apiCode: String) {
        switch apiCode {
        case "SUNLIGHT", "SL": self = .sunlight
        case "YUNSEUL", "YS": self = .reflection
        case "SUNSET", "SS": self = .sunset
        case "NIGHT_VIEW", "NV": self = .nightView
        default: return nil
        }
    }
}

enum WeatherSky: String, Codable, Sendable, Equatable {
    case clear = "CLEAR"
    case mostlyCloudy = "MOSTLY_CLOUDY"
    case overcast = "OVERCAST"

    var displayName: String {
        switch self {
        case .clear: "맑음"
        case .mostlyCloudy: "구름 많음"
        case .overcast: "흐림"
        }
    }
}

enum Precipitation: String, Codable, Sendable, Equatable {
    case none = "NONE"
    case rain = "RAIN"
    case rainSnow = "RAIN_SNOW"
    case snow = "SNOW"
    case shower = "SHOWER"

    var displayName: String {
        switch self {
        case .none: "없음"
        case .rain: "비"
        case .rainSnow: "비/눈"
        case .snow: "눈"
        case .shower: "소나기"
        }
    }
}

enum CongestionLevel: String, Codable, Sendable, Equatable, CaseIterable {
    case relaxed = "RELAXED"
    case normal = "NORMAL"
    case slightlyCrowded = "SLIGHTLY_CROWDED"
    case crowded = "CROWDED"

    var displayName: String {
        switch self {
        case .relaxed: "여유"
        case .normal: "보통"
        case .slightlyCrowded: "약간 붐빔"
        case .crowded: "붐빔"
        }
    }
}

/// 오픈 신청이 반려됐을 때 함께 내려오는 사유. 등록한 본인에게만 노출된다.
struct SpotRejectionInfo: Codable, Sendable, Equatable {
    /// 반려 사유 코드 (DUPLICATE / LOW_QUALITY / LOCATION_MISMATCH / FILTER_MISMATCH / ETC)
    let reason: String?
    /// 사유 코드의 한글 라벨 (예: "사진 상태 불량")
    let reasonLabel: String?
    /// 사용자 안내 문구
    let guideMessage: String?
    /// 운영자가 입력한 상세 사유 (reason == ETC 일 때 사용)
    let detail: String?
    /// 반려 시각 (ISO8601 문자열)
    let rejectedAt: String?
}

struct EmptyResponse: Decodable, Sendable, Equatable {}

enum BookmarkError: Error, Sendable, Equatable {
    case alreadyBookmarked
}
