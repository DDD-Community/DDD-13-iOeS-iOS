import SwiftUI

struct SpotSearchLocationButton: View {
    let action: () -> Void
    let debugLongPressAction: (() -> Void)?

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "mappin")
                    .font(.body.weight(.semibold))

                Text("장소 검색하기")
                    .pretendard(.body(.large(.bold)))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.spotOrange, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("장소 검색하기")
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.8)
                .onEnded { _ in
                    debugLongPressAction?()
                }
        )
    }
}
