import Foundation

struct SpotDetail: Codable, Sendable, Identifiable, Equatable {
    let spotId: Int64
    let name: String
    /// 한 줄 코멘트. 등록 시 선택 항목이라 비어 있을 수 있다.
    let comment: String?
    @LenientSpotTheme var theme: SpotTheme?
    let latitude: Double
    let longitude: Double
    /// 간략 주소(시·구). 서버가 채우지 못하면 null 로 온다.
    let address: String?
    /// 도로명 주소. 재신청 폼의 기존 주소 표시에 사용한다.
    let addressRoad: String?
    /// 지번 주소. 도로명 주소가 없을 때 기존 주소 표시에 사용한다.
    let addressJibun: String?
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

/// 사진 카테고리. `allCases` 순서가 곧 화면 노출 순서(햇살/윤슬/노을/야경)다.
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
    /// 서버 SpotTheme enum 과 1:1. 리스트 응답(`SpotItem.theme`)은 축약 코드로 내려오므로
    /// `init?(apiCode:)` 에서 양쪽을 모두 받는다. (SS=노을, YS=윤슬, SL=햇살, NV=야경)
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

    /// 표시명. rawValue 가 곧 한글 표기다.
    var displayName: String { rawValue }

    /// 카테고리 아이콘 에셋. 탐색 필터 칩·등록폼 칩·리스트 셀 오버레이가 공유한다.
    var iconAssetName: String {
        switch self {
        case .sunlight: "icon_photo_category_sunlight"
        case .reflection: "icon_photo_category_reflection"
        case .sunset: "icon_photo_category_sunset"
        case .nightView: "icon_photo_category_nightview"
        }
    }

    /// 에셋 누락 시 AssetImage 가 쓰는 폴백.
    var iconEmoji: String {
        switch self {
        case .sunlight: "☀️"
        case .reflection: "🌊"
        case .sunset: "🌇"
        case .nightView: "🌙"
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
