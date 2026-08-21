import Alamofire
import Foundation

/// 카테고리 다중선택 필터의 쿼리 표현을 한곳에 모아둔다.
///
/// 서버는 **반복 파라미터**로 받는다 — `?theme=SUNSET&theme=YUNSEUL` (BE PR #162).
/// 파라미터를 아예 빼면 전체 조회다(서버가 null/빈 리스트를 모두 "필터 없음"으로 처리).
/// `GET /v1/spots` 와 `GET /v1/spots/viewport` 두 곳에 동일하게 적용된다.
enum SpotThemeQuery {
    static let parameterName = "theme"

    /// Alamofire 의 기본 `URLEncoding` 은 배열을 `theme[]=SUNSET` 으로 직렬화한다.
    /// 서버가 기대하는 반복 키(`theme=SUNSET&theme=YUNSEUL`) 를 만들려면 대괄호를 빼야 한다.
    static let encoding = URLEncoding(arrayEncoding: .noBrackets)

    /// 선택이 비어 있으면(= 전체) `nil` 을 돌려 쿼리에서 아예 빠지게 한다.
    /// 순서는 `SpotTheme.allCases` 기준으로 고정 — 요청이 Set 순서에 따라 흔들리지 않게.
    static func values(for themes: Set<SpotTheme>) -> [String]? {
        guard !themes.isEmpty else { return nil }
        return SpotTheme.allCases
            .filter(themes.contains)
            .map(\.apiCode)
    }
}
