import SwiftUI

/// 상세 화면 최하단의 "스팟 삭제하기" 링크.
struct SpotDeleteLink: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("스팟 삭제하기")
                .pretendard(.body(.medium()))
                .foregroundStyle(Color.spotDeleteLink)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
