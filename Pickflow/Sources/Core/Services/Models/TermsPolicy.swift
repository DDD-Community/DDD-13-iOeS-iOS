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

extension TermsPolicy {
    /// config API가 약관 정보를 내려주지 않을 때(서버 미반영/응답 실패) 사용할 기본값.
    static let fallback: [TermsPolicy] = [
        TermsPolicy(
            type: "TERMS_OF_SERVICE",
            title: "서비스 이용약관",
            url: "https://cubic-print-1cb.notion.site/abe90976df958360b53001e6ee774eb3?pvs=143"
        ),
        TermsPolicy(
            type: "LOCATION_TERMS",
            title: "위치정보 서비스 이용약관",
            url: "https://cubic-print-1cb.notion.site/36390976df9580289cc9ebcba9ed7ffd?pvs=143"
        ),
        TermsPolicy(
            type: "PRIVACY_POLICY",
            title: "개인정보처리방침",
            url: "https://cubic-print-1cb.notion.site/07a90976df958319b6d1013e089c5ee6?pvs=143"
        ),
    ]
}
