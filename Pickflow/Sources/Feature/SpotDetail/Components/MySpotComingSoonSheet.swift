import SwiftUI

struct MySpotComingSoonSheet: View {
    let onCancel: () -> Void
    let onNotify: () -> Void

    var body: some View {
        VStack(spacing: 24) {
          Spacer(minLength: 0)
            VStack(spacing: 12) {
                Text("나만의 포토 스팟,\n곧 오픈할 수 있어요!")
                    .pretendard(.heading(.medium))
                    .foregroundStyle(.gray0)
                    .multilineTextAlignment(.center)

                VStack(spacing: 4) {
                    Text("나만 알기 아까운 포토 스팟을\n세상에 공개할 준비가 되었나요?")
                        .pretendard(.body(.medium()))
                        .foregroundStyle(.gray30)
                        .multilineTextAlignment(.center)

                    Text("기능이 업데이트되면 가장 먼저 알려드릴게요.")
                        .pretendard(.body(.medium(.bold)))
                        .foregroundStyle(.gray0)
                        .multilineTextAlignment(.center)
                }
            }

            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("괜찮아요")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(.gray80)
                        .frame(height: 56)
                        .padding(.horizontal, 30)
                }
                .background(.gray0)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Button(action: onNotify) {
                    HStack(spacing: 6) {
                      Image(.icNotiActive)
                        Text("업데이트 소식 받기")
                            .pretendard(.body(.large(.bold)))
                            .foregroundStyle(.gray0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .background(.sunsetOrange)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 26)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(UIAsset.Colors.gray95.swiftUIColor)
    }
}
