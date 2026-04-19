import SwiftUI

/// 앱 런치 시 첫 뷰. 실질 라우팅은 `AppRootView`에서 수행한다.
struct ContentView: View {
    var body: some View {
        AppRootView(authService: getAuthService())
    }
}

#Preview {
    ContentView()
}
