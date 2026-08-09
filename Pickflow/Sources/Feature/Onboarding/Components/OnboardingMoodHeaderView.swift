import SwiftUI

/// Step 2/3 일러스트 상단의 mood 헤더.
/// - 위: secondary mood (비선택, 59×28, opacity 50%)
/// - 아래: primary mood (선택, 84×40, mood별 stroke)
/// - 그 아래: 설명 문구 (Pretendard body medium)
/// 칩은 capsule이 아닌 RoundedRectangle(cornerRadius: 5).
struct OnboardingMoodHeaderView: View {
    let header: OnboardingMoodHeader

    private enum ChipSize {
        static let smallWidth: CGFloat = 59
        static let smallHeight: CGFloat = 28
        static let largeWidth: CGFloat = 84
        static let largeHeight: CGFloat = 40
        static let cornerRadius: CGFloat = 5
    }

    var body: some View {
        VStack(spacing: 12) {
            moodChip(
                header.secondary,
                width: ChipSize.smallWidth,
                height: ChipSize.smallHeight,
                isSelected: false
            )
            .opacity(0.5)

            moodChip(
                header.primary,
                width: ChipSize.largeWidth,
                height: ChipSize.largeHeight,
                isSelected: true
            )

            Text(header.description)
                .pretendard(.body(.medium()))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.top, 4)
        }
    }

    private func moodChip(
        _ mood: SpotTheme,
        width: CGFloat,
        height: CGFloat,
        isSelected: Bool
    ) -> some View {
        let isLarge = height >= ChipSize.largeHeight
        return HStack(spacing: 4) {
            Image(mood.iconAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: isLarge ? 18 : 14, height: isLarge ? 18 : 14)
            Text(mood.rawValue)
                .pretendard(isLarge ? .body(.medium(.bold)) : .body(.small()))
                .foregroundStyle(.white)
        }
        .frame(width: width, height: height)
        .background(OnboardingPalette.panelBackground, in: RoundedRectangle(cornerRadius: ChipSize.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: ChipSize.cornerRadius)
                .stroke(isSelected ? mood.accentColor : .clear, lineWidth: 1)
        )
    }
}

#Preview("Step 2 (sunset)") {
    OnboardingMoodHeaderView(
        header: OnboardingMoodHeader(
            primary: .sunset,
            secondary: .reflection,
            description: "해가 뜨거나 지려고 할 때에\n하늘이 햇빛을 받아 붉게 보이는 현상"
        )
    )
    .padding()
    .background(Color.black)
}

#Preview("Step 3 (reflection)") {
    OnboardingMoodHeaderView(
        header: OnboardingMoodHeader(
            primary: .reflection,
            secondary: .sunset,
            description: "달빛이나 햇빛에 비치어 반짝이는 잔물결"
        )
    )
    .padding()
    .background(Color.black)
}
