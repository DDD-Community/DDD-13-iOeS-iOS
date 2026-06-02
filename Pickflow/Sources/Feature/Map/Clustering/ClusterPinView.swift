import SwiftUI

struct ClusterPinView: View {
    let count: Int
    var isSelected: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(.sunsetOrange)
            Text("\(count)")
                .pretendard(.body(.small(.bold)))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .overlay {
            if isSelected {
                Circle().strokeBorder(Color(.sunsetOrange), lineWidth: 4)
            }
        }
        .frame(width: ClusterPinView.diameter(forCount: count), height: ClusterPinView.diameter(forCount: count))
    }

    static func diameter(forCount count: Int) -> CGFloat {
        count < 16 ? 60 : 100   // M(60×60): 2–15, L(100×100): 16+
    }
}
