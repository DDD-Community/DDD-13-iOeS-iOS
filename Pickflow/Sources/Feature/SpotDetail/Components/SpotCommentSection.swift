import SwiftUI

struct SpotCommentSection: View {
    let comment: String
    let recordedTime: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("스팟 한 줄 코멘트")
                .pretendard(.body(.large(.bold)))
                .foregroundStyle(.gray0)

            if let recordedTime {
                Text("기록 시간: \(DateFormatter.pickflowDisplayTime(from: recordedTime))")
                    .pretendard(.body(.small(.bold)))
                    .foregroundStyle(.gray30)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(UIAsset.Colors.gray30.color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Text(comment)
                .pretendard(.body(.medium()))
                .foregroundStyle(.gray0)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
