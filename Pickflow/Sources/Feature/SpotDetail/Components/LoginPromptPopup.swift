import SwiftUI

struct LoginPromptPopup: View {
    let onCancel: () -> Void
    let onLogin: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("잠깐,\n로그인이 필요한 기능이에요")
                .pretendard(.heading(.small))
                .foregroundStyle(.gray0)
                .multilineTextAlignment(.center)

            Text("마음에 드는 스팟을 놓치지 않도록\n지금 바로 연결해 보세요.\n간편 로그인으로 바로 시작할 수 있습니다.")
                .pretendard(.body(.medium()))
                .foregroundStyle(.gray50)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("취소")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(.gray95)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .background(.gray0)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Button(action: onLogin) {
                    Text("간편 로그인하기")
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
        .padding(24)
        .background(UIAsset.Colors.gray90.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
