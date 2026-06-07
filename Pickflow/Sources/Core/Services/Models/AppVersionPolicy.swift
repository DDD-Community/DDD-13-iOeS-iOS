import Foundation

/// 서버가 내려주는 iOS 앱 버전 정책.
///
/// `GET /v1/app/config/ios` 응답의 `data` 필드와 매핑된다.
struct AppVersionPolicy: Decodable, Sendable, Equatable {
    /// 이 버전 미만이면 앱 사용 불가.
    let minimumVersion: String
    /// 앱스토어 기준 최신 버전.
    let latestVersion: String
    /// 강제 업데이트 기능 on/off 스위치.
    let forceUpdate: Bool
    /// 앱스토어 이동 URL.
    let storeUrl: String
    /// 고객센터 1:1 문의 이메일. 서버가 내려줄 때만 채워진다(미반영 시 클라이언트 기본값 사용).
    let supportEmail: String?
    /// 약관/정책 문서 목록. 서버가 내려줄 때만 채워진다(미반영 시 클라이언트 기본값 사용).
    let termsPolicies: [TermsPolicy]?
}
