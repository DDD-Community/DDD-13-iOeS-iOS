import SwiftUI

struct ReportButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                AssetImage(named: "icErrorOutline", size: 16) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(.gray50)
                }
                Text("잘못된 정보가 있나요?")
                    .pretendard(.body(.medium()))
                    .foregroundStyle(.gray50)
                    .underline()
            }
        }
        .frame(maxWidth: .infinity)
    }
}
