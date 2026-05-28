import SwiftUI

struct SpotSearchLocationButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                AssetImage(named: "icon_location_mark", renderingMode: .template, size: 24) {
                    Image(systemName: "mappin")
                        .font(.system(size: 24, weight: .semibold))
                }

                Text("어디에서 찍으셨나요?")
                    .pretendard(.body(.large(.bold)))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.spotOrange, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("장소 검색하기")
    }
}
