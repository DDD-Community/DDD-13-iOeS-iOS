import SwiftUI
import WebKit

/// 외부 웹 페이지를 표시하는 `WKWebView` 래퍼.
struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    /// 지정 시 `WKWebView`의 User-Agent를 덮어쓴다.
    /// 일부 페이지(예: Notion 임베드 PDF)는 모바일 UA에서 본문 대신 파일 블록만 내려주므로
    /// 데스크탑 UA를 넘겨 데스크탑 레이아웃으로 렌더링하기 위해 사용한다.
    var customUserAgent: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        if let customUserAgent {
            webView.customUserAgent = customUserAgent
        }
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool

        init(isLoading: Binding<Bool>) {
            _isLoading = isLoading
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            isLoading = false
        }
    }
}
