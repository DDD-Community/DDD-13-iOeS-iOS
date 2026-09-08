#if DEBUG
import SwiftUI

/// Dev Mode 목 화면 공통 껍데기.
///
/// 목으로 띄우는 화면들은 원래 탭 루트라 헤더가 상단 안전영역까지 덮는 경우가 많고,
/// 그러면 기본 뒤로가기 버튼이 가려져 빠져나올 수 없다. 닫기 버튼을 항상 위에 얹는다.
struct MockScreenContainer<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .overlay(alignment: .topLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.5), in: Circle())
                }
                .padding(.leading, 16)
                .padding(.top, 8)
                .accessibilityLabel("목 화면 닫기")
            }
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
    }
}
#endif
