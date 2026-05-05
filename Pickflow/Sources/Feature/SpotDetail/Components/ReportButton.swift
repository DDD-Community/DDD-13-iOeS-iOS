import SwiftUI

struct ReportButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("잘못된 정보가 있나요?", systemImage: "info.circle")
                .pretendard(.body(.medium()))
                .foregroundStyle(.gray50)
                .underline()
        }
        .frame(maxWidth: .infinity)
    }
}
