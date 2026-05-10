import SwiftUI

struct CongestionInfoPopup: View {
    let onDismiss: () -> Void

    private let levels: [(level: Congestion, color: Color, description: String)] = [
        (.relaxed,         .green,                                        "방문객이 적어 여유롭게 즐길 수 있어요."),
        (.normal,          .yellow,                                       "적당한 인원이 있어 쾌적하게 즐길 수 있어요."),
        (.slightlyCrowded, UIAsset.Colors.sunsetOrange.swiftUIColor,     "방문객이 다소 많아 붐빌 수 있어요."),
        (.crowded,         .red,                                          "방문객이 많아 혼잡할 수 있어요."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("혼잡도 안내")
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(.gray0)
                Spacer()
                Button(action: onDismiss) {
                    AssetImage(named: "icClose", size: 24) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.gray0)
                    }
                }
            }
            .padding(.bottom, 20)

            VStack(alignment: .leading, spacing: 14) {
                ForEach(levels, id: \.level) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 8, height: 8)
                            .padding(.top, 5)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.level.rawValue)
                                .pretendard(.body(.medium(.bold)))
                                .foregroundStyle(.gray0)
                            Text(item.description)
                                .pretendard(.body(.small()))
                                .foregroundStyle(.gray50)
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
