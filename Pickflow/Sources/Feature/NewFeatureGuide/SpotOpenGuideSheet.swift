import SwiftUI

struct SpotOpenGuideSheet: View {
    let onOpenSpot: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            spotOpenPreview

            VStack(spacing: 12) {
                Text("스팟 공개 OPEN!")
                    .pretendard(.heading(.medium))
                    .foregroundStyle(.gray0)
                    .multilineTextAlignment(.center)

                Text("내가 기록한 스팟을 다른 유저에게 공개할 수 있어요")
                    .pretendard(.body(.medium()))
                    .foregroundStyle(.gray30)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 20) {
                Button(action: onOpenSpot) {
                    HStack(spacing: 8) {
                        Text("내 스팟 오픈하러 가기")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(.sunsetOrange)
                    .frame(height: 44)
                    .padding(.horizontal, 16)
                }
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.sunsetOrange, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Button(action: onConfirm) {
                    Text("확인했어요")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(.gray80)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .background(.gray0)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 26)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(UIAsset.Colors.gray95.swiftUIColor)
    }

    private var spotOpenPreview: some View {
        Image("spot_open_guide_preview")
            .resizable()
            .scaledToFit()
            .frame(width: 350, height: 170)
            .padding(.horizontal, 20)
    }
}

#Preview {
    SpotOpenGuideSheet(onOpenSpot: {}, onConfirm: {})
}
