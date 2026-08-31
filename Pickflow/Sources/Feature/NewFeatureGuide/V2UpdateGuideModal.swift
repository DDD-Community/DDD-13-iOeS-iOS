import SwiftUI

struct V2UpdateGuideModal: View {
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 20) {
                    Text("NEW")
                        .pretendard(.body(.small(.bold)))
                        .foregroundStyle(.sunsetOrange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(UIAsset.Colors.sunsetOrange.swiftUIColor.opacity(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Text("V2 업데이트 안내")
                        .pretendard(.heading(.medium))
                        .foregroundStyle(.gray0)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. 햇살 · 야경 필터가 추가되었어요")
                        Text("2. 이제 내 스팟을 공개할 수 있어요")
                    }
                    .pretendard(.body(.medium()))
                    .foregroundStyle(.gray30)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 30)
                }

                Button(action: onConfirm) {
                    Text("확인했어요")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .background(.sunsetOrange)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(20)
            .background(UIAsset.Colors.gray95.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    V2UpdateGuideModal(onConfirm: {})
}
