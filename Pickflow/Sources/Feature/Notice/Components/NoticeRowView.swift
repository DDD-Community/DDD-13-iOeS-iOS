import SwiftUI

/// 공지사항 목록 셀. (Figma 1084:5709) 제목 2줄 말줄임 + 본문 미리보기 1줄 + 날짜.
struct NoticeRowView: View {
    let item: NoticeListItem

    private var preview: String? {
        guard let content = item.content?.trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty else { return nil }
        return content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .pretendard(.body(.large()))
                .foregroundStyle(.gray0)
                .lineLimit(2)
                .truncationMode(.tail)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let preview {
                Text(preview)
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray30)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(DateFormatter.noticeDisplayDate(from: item.createdAt))
                .pretendard(.body(.small()))
                .foregroundStyle(.gray40)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
