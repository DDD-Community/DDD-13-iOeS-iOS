import SwiftUI

struct SpotActionButtons: View {
    let onRoute: () -> Void
    let onShare: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onRoute) {
                Label("길 안내 받기", systemImage: "location.fill")
                    .pretendard(.body(.large(.bold)))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
            }
            .foregroundStyle(.gray0)
            .background(.sunsetOrange)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button(action: onShare) {
                Label("공유하기", systemImage: "square.and.arrow.up")
                    .pretendard(.body(.large(.bold)))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
            }
            .foregroundStyle(.gray80)
            .background(.gray0)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
