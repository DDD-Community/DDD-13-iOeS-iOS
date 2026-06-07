import Foundation

/// 약관/정책 문서.
///
/// 앱 config API(`GET /v1/app/config/ios`) 응답 `data.termsPolicies` 항목과 매핑된다.
struct TermsPolicy: Decodable, Sendable, Identifiable, Hashable {
    /// 문서 종류 식별자(예: `TERMS_OF_SERVICE`). 제목 텍스트와 무관하게 분기/정렬 기준으로 사용한다.
    let type: String
    /// 화면에 노출되는 문서 제목.
    let title: String
    /// 문서 원문 웹 URL.
    let url: String

    var id: String { type }

    var documentURL: URL? { URL(string: url) }
}
