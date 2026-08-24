import SwiftUI

/// 오픈 승인 후 상세에 처음 진입했을 때 뜨는 완료 팝업.
struct SpotOpenCompletePopup: View {
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("MY 스팟 오픈 완료!")
                    .pretendard(.heading(.small))
                    .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)
                Text("이제 다른 사용자들도 이 스팟을 볼 수 있어요. 화면 하단의 ‘스팟 공개’에서\n언제든 공개 여부를 변경할 수 있어요.")
                    .pretendard(.body(.medium()))
                    .foregroundStyle(UIAsset.Colors.gray30.swiftUIColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(action: onConfirm) {
                Text("확인했어요")
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .background(UIAsset.Colors.sunsetOrange.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.top, 24)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(width: 328)
        .background(UIAsset.Colors.gray90.swiftUIColor, in: RoundedRectangle(cornerRadius: 16))
    }
}
