import Foundation

/// 카테고리 다중선택 필터의 쿼리 표현을 한곳에 모아둔다.
/// 서버 형식이 확정되면 이 파일만 고치면 되고, 엔드포인트/서비스/뷰모델은 건드릴 필요 없다.
enum SpotThemeQuery {
    // TODO(BE-API): 2026.08.14 스펙 기준 `GET /v1/spots` 의 필터는 단수 `theme` 하나뿐이고
    // 다중선택을 받지 않는다. 아래는 콤마 조인(`themes=SUNLIGHT,YUNSEUL`) 가정값으로,
    // 서버가 다중선택을 지원하면 parameterName 과 value 만 교체하면 된다.
    // 지원 계획이 없으면 호출부를 단일선택으로 되돌려야 한다.
    static let parameterName = "themes"

    /// 선택이 비어 있으면(= 전체) `nil` 을 돌려 쿼리에서 아예 빠지게 한다.
    /// 순서는 `SpotTheme.allCases` 기준으로 고정 — 요청이 Set 순서에 따라 흔들리지 않게.
    static func value(for themes: Set<SpotTheme>) -> String? {
        guard !themes.isEmpty else { return nil }
        return SpotTheme.allCases
            .filter(themes.contains)
            .map(\.apiCode)
            .joined(separator: ",")
    }
}
