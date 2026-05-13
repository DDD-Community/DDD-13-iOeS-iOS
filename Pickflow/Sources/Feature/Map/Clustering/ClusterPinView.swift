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
        switch count {
        case ..<10: return 44
        case ..<50: return 54
        case ..<100: return 64
        default: return 74
        }
    }
}
