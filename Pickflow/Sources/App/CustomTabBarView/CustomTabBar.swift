import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Tab

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
        } label: {
            VStack(spacing: 8) {
                Image(tab.iconName)
                    .renderingMode(.template)

                Text(tab.rawValue)
                    .pretendard(.label(.medium))
            }
            .foregroundStyle(isSelected ? .gray0 : .gray50)
            .frame(maxWidth: .infinity)
            .padding(.top, 14)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
