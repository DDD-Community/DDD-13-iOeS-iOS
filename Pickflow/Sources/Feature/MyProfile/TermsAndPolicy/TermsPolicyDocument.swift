import Foundation

/// 약관 및 정책 화면에서 노출되는 개별 문서.
struct TermsPolicyDocument: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let url: URL

    static let all: [TermsPolicyDocument] = [
        TermsPolicyDocument(
            title: "서비스 이용약관",
            url: URL(string: "https://cubic-print-1cb.notion.site/abe90976df958360b53001e6ee774eb3")!
        ),
        // TODO: [KAN-134] 위치정보 서비스 이용약관 실제 URL로 교체 (현재 TBD)
        TermsPolicyDocument(
            title: "위치정보 서비스 이용약관",
            url: URL(string: "https://cubic-print-1cb.notion.site/abe90976df958360b53001e6ee774eb3")!
        ),
        // TODO: [KAN-134] 개인정보처리방침 실제 URL로 교체 (현재 TBD)
        TermsPolicyDocument(
            title: "개인정보처리방침",
            url: URL(string: "https://cubic-print-1cb.notion.site/abe90976df958360b53001e6ee774eb3")!
        ),
    ]
}
