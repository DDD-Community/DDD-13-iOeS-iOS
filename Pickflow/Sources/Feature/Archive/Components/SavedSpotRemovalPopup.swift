import SwiftUI

/// 비공개로 전환된 저장 스팟을 탭했을 때 뜨는 삭제 확인 팝업.
struct SavedSpotRemovalPopup: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("저장 목록에서 삭제할까요?")
                    .pretendard(.heading(.small))
                    .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)
                Text("삭제하면 저장 목록에서\n더 이상 표시되지 않아요.")
                    .pretendard(.body(.medium()))
                    .foregroundStyle(UIAsset.Colors.gray30.swiftUIColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                Button(action: onCancel) {
                    Text("취소")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(UIAsset.Colors.gray80.swiftUIColor)
                        .padding(.horizontal, 28)
                        .frame(height: 52)
                }
                .background(UIAsset.Colors.gray0.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Button(action: onConfirm) {
                    Text("저장 목록에서 삭제")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .background(UIAsset.Colors.sunsetOrange.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.top, 24)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(width: 328)
        .background(UIAsset.Colors.gray90.swiftUIColor, in: RoundedRectangle(cornerRadius: 16))
    }
}
