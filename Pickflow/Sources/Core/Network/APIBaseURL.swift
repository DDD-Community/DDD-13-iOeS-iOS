import Foundation

/// 모든 엔드포인트가 참조하는 단일 base URL.
///
/// 인증 계열(`AuthEndpoint`, `AuthInterceptor`)도 반드시 여기를 거쳐야 한다.
/// 예전에는 `AppConfig.baseURL` 이 따로 있어서, 한쪽만 바꾸면 인증만 다른 서버로
/// 나가는 사고가 날 수 있는 구조였다.
enum APIBaseURL {
    static var current: String { APIEnvironment.current.baseURL }
}
