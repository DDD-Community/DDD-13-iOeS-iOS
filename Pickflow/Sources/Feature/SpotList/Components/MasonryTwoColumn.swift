import SwiftUI

/// 인덱스 짝/홀로 두 컬럼에 나눠 배치하는 Masonry(2열 비대칭) 그리드.
struct MasonryTwoColumn<Item: Identifiable, Cell: View>: View {
    let items: [Item]
    let spacing: CGFloat
    let onAppearItem: ((Item) -> Void)?
    @ViewBuilder let cell: (Item) -> Cell

    init(
        items: [Item],
        spacing: CGFloat = 12,
        onAppearItem: ((Item) -> Void)? = nil,
        @ViewBuilder cell: @escaping (Item) -> Cell
    ) {
        self.items = items
        self.spacing = spacing
        self.onAppearItem = onAppearItem
        self.cell = cell
    }

    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            column(parityEven: true)
            column(parityEven: false)
        }
    }

    private func column(parityEven: Bool) -> some View {
        LazyVStack(spacing: spacing) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if (index % 2 == 0) == parityEven {
                    cell(item)
                        .onAppear { onAppearItem?(item) }
                }
            }
        }
    }
}
