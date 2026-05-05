import SwiftUI

struct SunsetTimelineSection: View {
    let sunsetTime: String

    private var progress: CGFloat {
        CGFloat(DateFormatter.minutesFromMidnight(from: sunsetTime) ?? 0) / CGFloat(24 * 60)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("일몰 시간")
                .pretendard(.body(.small(.bold)))
                .foregroundStyle(.gray50)

            GeometryReader { proxy in
                let width = proxy.size.width
                let dotSize: CGFloat = 8
                let timelineY: CGFloat = 46
                let timelineIconSize: CGFloat = 16
                let labelHeight: CGFloat = 32
                let labelToDotGap: CGFloat = 8
                let indicatorX = max(4, min(width - 4, width * progress))
                let labelWidth: CGFloat = 82
                let labelX = max(labelWidth / 2, min(width - labelWidth / 2, indicatorX))
                let dotTopY = timelineY + ((timelineIconSize - dotSize) / 2)
                let labelCenterY = dotTopY - labelToDotGap - (labelHeight / 2)

                ZStack(alignment: .topLeading) {
                    Text(DateFormatter.pickflowDisplayTime(from: sunsetTime))
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(.sunsetOrange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(UIAsset.Colors.sunsetOrange.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .fixedSize()
                        .frame(height: labelHeight)
                        .position(x: labelX, y: labelCenterY)

                    HStack(spacing: 0) {
                        Image("icSunny", bundle: PickflowResources.bundle)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        ForEach(0..<23, id: \.self) { _ in
                            Circle()
                                .fill(.gradientYellow)
                                .frame(width: 2, height: 2)
                                .frame(maxWidth: .infinity)
                        }
                        Image("icNight", bundle: PickflowResources.bundle)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                    .overlay(alignment: .leading) {
                        Circle()
                            .fill(.gray0)
                            .frame(width: dotSize, height: dotSize)
                            .offset(x: indicatorX - (dotSize / 2))
                    }
                    .offset(y: timelineY)

                    LinearGradient(
                        colors: [UIAsset.Colors.gradientYellow.color, UIAsset.Colors.gradientYellowEnd.color],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 8)
                    .offset(y: 68)
                }
            }
            .frame(height: 76)
        }
    }
}
