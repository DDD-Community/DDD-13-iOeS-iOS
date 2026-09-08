import SwiftUI

/// 재신청 폼에서 뒤로 나갈 때 뜨는 이탈 확인 팝업.
/// - TODO(PV-40): 오픈 완료·저장 삭제 팝업과 뼈대가 같다. 세 번째가 생겼으니 공용 컴포넌트로 뽑을 것.
struct SpotRegistrationExitConfirmPopup: View {
    let onContinue: () -> Void
    let onLeave: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("이대로 나갈까요?")
                    .pretendard(.heading(.small))
                    .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)
                Text("등록하지 않은 내용은 사라져요.")
                    .pretendard(.body(.medium()))
                    .foregroundStyle(UIAsset.Colors.gray30.swiftUIColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                Button(action: onContinue) {
                    Text("계속하기")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(UIAsset.Colors.gray80.swiftUIColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .background(UIAsset.Colors.gray0.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Button(action: onLeave) {
                    Text("나가기")
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
