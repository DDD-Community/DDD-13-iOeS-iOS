import SwiftUI

struct SpotDetailPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    let spotId: SpotId

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.spotBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("스팟 상세")
                        .pretendard(.heading(.medium))
                        .foregroundStyle(.white)

                    Text("모달 전환 테스트용 placeholder 화면입니다.")
                        .pretendard(.body(.medium()))
                        .foregroundStyle(Color.spotTertiaryText)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Spot ID")
                        .pretendard(.body(.small(.bold)))
                        .foregroundStyle(Color.spotSecondaryText)

                    Text(spotId.rawValue)
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(.white)
                        .textSelection(.enabled)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.spotInputBackground, in: RoundedRectangle(cornerRadius: 12))

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 80)
            .padding(.bottom, 32)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .padding(.top, 24)
            .padding(.trailing, 12)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
