import SwiftUI

struct SpotOpenGuideSheet: View {
    let onOpenSpot: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(UIAsset.Colors.gray50.swiftUIColor)
                .frame(width: 48, height: 4)
                .padding(.top, 8)

            spotOpenPreview

            VStack(spacing: 12) {
                Text("스팟 공개 OPEN!")
                    .pretendard(.heading(.medium))
                    .foregroundStyle(.gray0)
                    .multilineTextAlignment(.center)

                Text("직접 기록한 포토 스팟을 공개하면\n다른 유저들도 지도에서 발견할 수 있어요.")
                    .pretendard(.body(.medium()))
                    .foregroundStyle(.gray40)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
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
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 26)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(UIAsset.Colors.gray95.swiftUIColor)
    }

    private var spotOpenPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(UIAsset.Colors.gray90.swiftUIColor)

            VStack(spacing: 8) {
                LinearGradient(
                    colors: [
                        UIAsset.Colors.sunsetOrange.swiftUIColor.opacity(0.55),
                        UIAsset.Colors.gray80.swiftUIColor
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(alignment: .bottomLeading) {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 9, weight: .semibold))
                        Text("서울특별시 송파구 올림픽로 240")
                    }
                    .pretendard(.label(.xsmall))
                    .foregroundStyle(.gray10)
                    .padding(8)
                }

                HStack(spacing: 8) {
                    Text("길 안내 받기")
                        .pretendard(.label(.small))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(.sunsetOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Text("내 스팟 오픈하기")
                        .pretendard(.label(.small))
                        .foregroundStyle(.gray80)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(.gray0)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                Text("공유 API를 활용한 실시간 정보를 확인해 보세요")
                    .pretendard(.label(.xsmall))
                    .foregroundStyle(.gray40)
            }
            .padding(12)
        }
        .frame(height: 172)
        .padding(.horizontal, 20)
    }
}

#Preview {
    SpotOpenGuideSheet(onOpenSpot: {}, onConfirm: {})
}
