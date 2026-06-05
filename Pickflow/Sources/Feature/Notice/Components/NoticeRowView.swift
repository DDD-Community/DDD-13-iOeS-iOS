import SwiftUI

/// 공지사항 목록 셀. (Figma 1703:20237)
/// 날짜 칩 → 제목(SemiBold 1줄 말줄임) → 본문 미리보기(1줄 말줄임).
/// 읽음 상태면 전체를 gray40으로 디밍, 안읽음이면 gray0으로 강조.
struct NoticeRowView: View {
    let item: NoticeListItem

    private var foreground: Color {
        item.isRead ? UIAsset.Colors.gray40.color : UIAsset.Colors.gray0.color
    }

    private var preview: String? {
        guard let content = item.content?.trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty else { return nil }
        return content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(DateFormatter.noticeDisplayDate(from: item.createdAt))
                .pretendard(.body(.small()))
                .foregroundStyle(foreground)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(UIAsset.Colors.gray90.color)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(foreground)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let preview {
                    Text(preview)
                        .pretendard(.body(.small()))
                        .foregroundStyle(foreground)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
