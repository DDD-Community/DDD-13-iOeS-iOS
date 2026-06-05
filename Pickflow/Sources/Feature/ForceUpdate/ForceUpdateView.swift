import SwiftUI

/// 강제 업데이트 화면.
///
/// 닫기 버튼 없이 "업데이트하기" 버튼만 제공하며, 버튼을 누르면 앱스토어로 이동한다.
struct ForceUpdateView: View {
    let storeURL: URL
    private let onUpdate: (URL) -> Void

    init(storeURL: URL, onUpdate: @escaping (URL) -> Void) {
        self.storeURL = storeURL
        self.onUpdate = onUpdate
    }

    var body: some View {
        ZStack {
            Color("gray0").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                AssetImage(named: "AppLogoMark", size: 72) {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .foregroundStyle(Color("sunsetOrange"))
                }
                .padding(.bottom, 24)

                Text("업데이트가 필요해요")
                    .pretendard(.heading(.medium))
                    .foregroundStyle(Color("gray100"))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)

                Text("안정적인 서비스 이용을 위해\n최신 버전으로 업데이트해 주세요.")
                    .pretendard(.body(.medium()))
                    .foregroundStyle(Color("gray70"))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button {
                    onUpdate(storeURL)
                } label: {
                    Text("업데이트하기")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(Color("gray0"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color("sunsetOrange"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    ForceUpdateView(
        storeURL: URL(string: "https://apps.apple.com/app/id000000000")!,
        onUpdate: { _ in }
    )
}
