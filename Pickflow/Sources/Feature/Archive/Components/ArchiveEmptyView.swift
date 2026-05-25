import SwiftUI

struct ArchiveEmptyView: View {
    var onExploreTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 36) {
            VStack(spacing: 12) {
                Text("마음에 드는 스팟을\n발견하셨나요?")
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(.gray0)
                    .multilineTextAlignment(.center)

                Text("나만의 출사 리스트를 채워보세요.\n저장된 스팟은 여기서 언제든 확인할 수 있어요.")
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
                    .clipShape(RoundedRectangle(cornerRadius: 8))
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
