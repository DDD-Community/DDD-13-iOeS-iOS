import SwiftUI

struct CustomTabBar: View {
    /// CustomTabBar 컨텐츠 높이(아이콘 24 + spacing 8 + label ~14 + top padding 14).
    /// safe area inset 은 별도. 콘텐츠를 탭바 위로 올리고 싶을 때 padding.bottom 에 더한다.
    static let height: CGFloat = 60

    @Binding var selectedTab: Tab
    /// 탭 버튼이 눌릴 때마다 호출된다. 마이 탭 연타로 Dev Mode 에 진입하는 데 쓴다.
    /// 탭 전환 자체는 그대로 일어나므로 평소 사용에는 영향이 없다.
    var onTabTapped: (Tab) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Tab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 16)
        .background(.gray90)
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 8)
    }

    @ViewBuilder
    private func tabButton(for tab: Tab) -> some View {
        let isSelected = selectedTab == tab

        Button {
            selectedTab = tab
            onTabTapped(tab)
        } label: {
            VStack(spacing: 8) {
                Image(isSelected ? tab.selectedIconName : tab.iconName)
                    .renderingMode(.template)
                    .foregroundStyle(isSelected ? .gray0 : .gray50)

                Text(tab.rawValue)
                    .pretendard(.label(.medium))
                    .foregroundStyle(isSelected ? .gray0 : .gray50)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 14)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
