import SwiftUI

struct ArchiveEmptyView: View {
    var onExploreTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(.gray40)

            VStack(spacing: 8) {
                Text("저장된 스팟이 없어요")
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(.gray0)

                Text("마음에 드는 스팟을 저장해 보세요.")
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray50)
                    .multilineTextAlignment(.center)
            }

            Button(action: onExploreTap) {
                Text("스팟 둘러보기")
                    .pretendard(.body(.medium(.bold)))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(UIAsset.Colors.sunsetOrange.swiftUIColor)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ZStack {
        UIAsset.Colors.gray95.color.ignoresSafeArea()
        ArchiveEmptyView()
    }
}
