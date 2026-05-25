import SwiftUI

struct ArchiveMySpotPlaceholder: View {
    var onRegisterTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 36) {
            VStack(spacing: 12) {
                Text("나만 아는 특별한 스팟을\n기록해 보세요!")
                    .pretendard(.heading(.small))
                    .foregroundStyle(.gray0)
                    .multilineTextAlignment(.center)

                Text("직접 촬영한 사진과 함께 스팟을 등록하고,\n나만의 포토 지도를 완성해 보세요.")
                    .pretendard(.body(.medium()))
                    .foregroundStyle(.gray50)
                    .multilineTextAlignment(.center)
            }

            Button(action: onRegisterTap) {
                Text("첫 번째 스팟 등록하기")
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 47.5)
                    .background(UIAsset.Colors.sunsetOrange.swiftUIColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ZStack {
        UIAsset.Colors.gray95.color.ignoresSafeArea()
        ArchiveMySpotPlaceholder()
    }
}
