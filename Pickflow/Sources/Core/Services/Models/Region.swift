import Foundation

/// 탐색 화면 상단 지역 필터(대전/서울)의 단위. 스팟마다 부여된 regionId 기준으로 서버가 필터링한다.
struct Region: Codable, Sendable, Identifiable, Equatable {
    let id: Int
    let name: String
}

extension Region {
    /// 활성지역 조회 API(BE 확정 전) 실패·미연동 시 폴백. 대전이 기본값으로 먼저 노출되어야 한다.
    static let fallbackRegions: [Region] = [
        Region(id: 1, name: "대전"),
        Region(id: 2, name: "서울"),
    ]
}
