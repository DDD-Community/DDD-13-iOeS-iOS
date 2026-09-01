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
                        guideText(prefix: "1. ", highlighted: "햇살 · 야경 필터", suffix: "가 추가되었어요")
                        guideText(prefix: "2. 이제 내 ", highlighted: "스팟을 공개", suffix: "할 수 있어요")
                    }
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

    private func guideText(prefix: String, highlighted: String, suffix: String) -> Text {
        regularGuideText(prefix)
            + highlightedGuideText(highlighted)
            + regularGuideText(suffix)
    }

    private func regularGuideText(_ text: String) -> Text {
        Text(text)
            .font(PretendardStyle.body(.medium()).token.font)
            .tracking(PretendardStyle.body(.medium()).token.kerning)
            .foregroundColor(UIAsset.Colors.gray30.swiftUIColor)
    }

    private func highlightedGuideText(_ text: String) -> Text {
        Text(text)
            .font(PretendardToken(size: 15, lineHeight: 21, kerning: 0, weight: .semiBold).font)
            .foregroundColor(UIAsset.Colors.gray0.swiftUIColor)
    }
}

#Preview {
    V2UpdateGuideModal(onConfirm: {})
}
