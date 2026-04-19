import Foundation

/// 앱 전역 환경 설정값.
///
/// - Note: 실제 환경별(dev/stage/prod) URL은 §9 리소스 요청 단계에서 유저 확인 필요.
///   현재 값은 백엔드 명세 예시값이므로 반드시 교체할 것.
enum AppConfig {
    /// 백엔드 API Base URL.
    static let baseURL: String = "https://api.example.com/v1"
}
