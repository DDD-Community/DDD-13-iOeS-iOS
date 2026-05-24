import SwiftUI

struct CongestionInfoPopup: View {
    let onDismiss: () -> Void

    private let levels: [(level: CongestionLevel, range: String, description: String)] = [
        (.relaxed,         "50% 이하",  "인구가 평소와 비교하여 적음"),
        (.normal,          "50~75%",   "인구가 평소와 비교하여 비슷함"),
        (.slightlyCrowded, "75~100%",  "인구가 평소와 비교하여 많음"),
        (.crowded,         "100% 초과", "인구가 평소와 비교하여 매우 많음"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Text("혼잡도 표시 기준")
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
            .padding(.bottom, 28)

            VStack(alignment: .leading, spacing: 24) {
                ForEach(levels, id: \.level) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(item.level.displayName)
                                .pretendard(.heading(.large))
                                .foregroundStyle(.gray0)
                            Text(item.range)
                                .pretendard(.body(.small(.bold)))
                                .foregroundStyle(.sunsetOrange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.29, green: 0.10, blue: 0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        Text(item.description)
                            .pretendard(.body(.medium()))
                            .foregroundStyle(.gray50)
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(UIAsset.Colors.gray90.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
