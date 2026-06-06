import SwiftUI

/// 공지사항 리스트/상세 공통 네비게이션 바. (Figma I1084:5719;1084:7077)
/// 좌측 뒤로가기 + 중앙 타이틀. 우측 "등록" placeholder는 그리지 않고 균형용 빈 영역만 둔다.
struct NoticeNavBar: View {
    var title: String = "공지사항"
    var onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                AssetImage(named: "icon_back_arrow", renderingMode: .template, size: 28) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 28, weight: .regular))
                        .frame(width: 28, height: 28)
                }
                .foregroundStyle(UIAsset.Colors.gray0.color)
                .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로가기")

            Spacer()

            Text(title)
                .pretendard(.heading(.medium))
                .foregroundStyle(UIAsset.Colors.gray0.color)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
        .frame(height: 48)
        .padding(.horizontal, 16)
        .background(UIAsset.Colors.gray95.color)
    }
}
