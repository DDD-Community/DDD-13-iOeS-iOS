import Foundation

extension Bundle {
    /// 현재 앱의 표시 버전(`CFBundleShortVersionString`). 예: `"1.3.0"`.
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }
}
