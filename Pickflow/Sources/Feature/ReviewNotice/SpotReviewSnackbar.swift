import SwiftUI

/// 검수 결과를 알리는 스낵바. 자동으로 사라지지 않고, 이동하거나 닫을 때만 없어진다.
struct SpotReviewSnackbar: View {
    let notice: SpotReviewNotice
    let onAction: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(notice.title)
                    .pretendard(.body(.medium(.bold)))
                    .foregroundStyle(UIAsset.Colors.gray95.swiftUIColor)
                Text(notice.message)
                    .pretendard(.body(.small()))
                    .foregroundStyle(UIAsset.Colors.gray50.swiftUIColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onAction) {
                Text(notice.actionTitle)
                    .pretendard(.body(.medium(.bold)))
                    .foregroundStyle(UIAsset.Colors.sunsetOrange.swiftUIColor)
            }
            .buttonStyle(.plain)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(UIAsset.Colors.gray50.swiftUIColor)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("안내 닫기")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(UIAsset.Colors.gray0.swiftUIColor, in: RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
    }
}
