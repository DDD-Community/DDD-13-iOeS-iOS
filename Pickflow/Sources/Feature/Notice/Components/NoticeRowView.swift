import SwiftUI

/// 공지사항 목록 셀. (Figma 1084:5709) 제목 최대 2줄 말줄임 + 날짜.
struct NoticeRowView: View {
    let item: NoticeListItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .pretendard(.body(.large()))
                .foregroundStyle(.gray0)
                .lineLimit(2)
                .truncationMode(.tail)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(DateFormatter.noticeDisplayDate(from: item.createdAt))
                .pretendard(.body(.small()))
                .foregroundStyle(.gray40)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
