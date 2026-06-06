import SwiftUI

/// 로드 실패 상태 (리스트/상세 공통). 아이콘 + 메시지 + 다시 시도.
struct NoticeErrorView: View {
    let message: String
    var onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.sunsetOrange)

            Text(message)
                .pretendard(.body(.medium()))
                .foregroundStyle(.gray30)
                .multilineTextAlignment(.center)

            Button(action: onRetry) {
                Text("다시 시도")
                    .pretendard(.body(.medium(.bold)))
                    .foregroundStyle(.gray0)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.sunsetOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 빈 목록 상태.
struct NoticeEmptyView: View {
    var body: some View {
        Text("등록된 공지사항이 없어요")
            .pretendard(.body(.medium()))
            .foregroundStyle(.gray40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 로딩 상태.
struct NoticeLoadingView: View {
    var body: some View {
        ProgressView()
            .tint(UIAsset.Colors.gray0.color)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
