import SwiftUI

struct TermsAndPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let url: URL
    @State private var isLoading = true

    var body: some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()

            VStack(spacing: 0) {
                customHeader

                ZStack {
                    WebView(url: url, isLoading: $isLoading)

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
