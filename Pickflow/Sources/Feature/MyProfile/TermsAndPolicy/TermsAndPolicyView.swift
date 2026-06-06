import SwiftUI

struct TermsAndPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let url: URL
    @State private var isLoading = true

    // Notion 공개 페이지는 모바일 UA에서 임베드 PDF를 파일 블록으로만 노출하므로
    // 데스크탑 UA로 요청해 본문(PDF)이 인라인으로 렌더링되도록 한다.
    private let desktopUserAgent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    var body: some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()

            VStack(spacing: 0) {
                customHeader

                ZStack {
                    WebView(url: url, isLoading: $isLoading, customUserAgent: desktopUserAgent)

                    if isLoading {
                        ProgressView()
                            .tint(UIAsset.Colors.gray0.color)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Custom Header

    private var customHeader: some View {
        ZStack {
            Text(title)
                .pretendard(.heading(.small))
                .foregroundStyle(.gray0)

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.gray0)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
