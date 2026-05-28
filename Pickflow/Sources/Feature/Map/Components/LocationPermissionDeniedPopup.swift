import SwiftUI

struct LocationPermissionDeniedPopup: View {
    let onCancel: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Image(.icInfoRed)
                .frame(width: 48, height: 48)
                .padding(.top, 8)

            VStack(spacing: 12) {
                Text("필수 권한을 허용해주세요.")
                    .pretendard(.heading(.small))
                    .foregroundStyle(.gray0)
                    .multilineTextAlignment(.center)

                Text("위치 권한을 허용해주세요. 정확한 위치\n사용을 권장합니다.")
                    .pretendard(.body(.medium()))
                    .foregroundStyle(.gray50)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 20)

            HStack(spacing: 8) {
                Button(action: onCancel) {
                    Text("취소")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(.gray80)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .background(.gray0)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Button(action: onOpenSettings) {
                    Text("설정으로 이동")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .background(.sunsetOrange)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(UIAsset.Colors.gray90.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

