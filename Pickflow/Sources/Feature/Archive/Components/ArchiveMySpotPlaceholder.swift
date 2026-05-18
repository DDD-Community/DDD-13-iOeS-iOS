import SwiftUI

struct ArchiveMySpotPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(.gray40)

            Text("나만의 스팟을 기록할 수 있어요")
                .pretendard(.body(.large(.bold)))
                .foregroundStyle(.gray0)
                .multilineTextAlignment(.center)

            Text("곧 출시될 예정이에요.")
                .pretendard(.body(.small()))
                .foregroundStyle(.gray50)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ZStack {
        UIAsset.Colors.gray95.color.ignoresSafeArea()
        ArchiveMySpotPlaceholder()
    }
}
