import SwiftUI

struct ArchiveTabBar: View {
    let selectedTab: ArchiveTab
    let onTabChange: (ArchiveTab) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ArchiveTab.allCases, id: \.self) { tab in
                tabItem(tab)
            }
        }
        .background(UIAsset.Colors.gray95.swiftUIColor)
    }

    private func tabItem(_ tab: ArchiveTab) -> some View {
        let isSelected = tab == selectedTab
        return Button {
            onTabChange(tab)
        } label: {
            VStack(spacing: 0) {
                Text(tab.title)
                    .pretendard(isSelected ? .body(.medium(.bold)) : .body(.medium()))
                    .foregroundStyle(isSelected ? .gray0 : .gray50)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(.gray0)
                    .frame(height: 2)
                    .opacity(isSelected ? 1 : 0)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        UIAsset.Colors.gray95.color.ignoresSafeArea()
        VStack {
            ArchiveTabBar(selectedTab: .savedSpots, onTabChange: { _ in })
            ArchiveTabBar(selectedTab: .mySpots, onTabChange: { _ in })
        }
    }
}
