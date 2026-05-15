import SwiftUI

/// 정렬 드롭다운 헤더. 펼침 상태는 부모가 보유한다.
struct SpotListSortDropdownHeader: View {
    let sort: SpotListSort
    @Binding var isExpanded: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() }
        } label: {
            HStack(spacing: 4) {
                Text(sort.displayName)
                .pretendard(.body(.large(.bold)))
                    .foregroundStyle(.white)
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// 드롭다운 옵션 박스. 헤더 아래 overlay 로 표시한다.
struct SpotListSortDropdownOptions: View {
    let current: SpotListSort
    let onSelect: (SpotListSort) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(SpotListSort.allCases.enumerated()), id: \.element) { index, option in
                if index > 0 {
                    Divider()
                        .background(UIAsset.Colors.gray90.swiftUIColor)
                }
                row(option)
            }
        }
        .padding(.vertical, 4)
        .background(UIAsset.Colors.gray95.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .frame(width: 180)
    }

    private func row(_ option: SpotListSort) -> some View {
        let isSelected = option == current
        return Button {
            onSelect(option)
        } label: {
            HStack {
                Text(option.displayName)
                    .pretendard(.body(.large()))
                    .foregroundStyle(isSelected ? .sunsetOrange : .gray0)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(UIAsset.Colors.sunsetOrange.swiftUIColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(rowBackground(isSelected: isSelected))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func rowBackground(isSelected: Bool) -> Color {
        isSelected
            ? UIAsset.Colors.sunsetOrange.swiftUIColor.opacity(0.2)
            : UIAsset.Colors.gray95.swiftUIColor
    }
}
