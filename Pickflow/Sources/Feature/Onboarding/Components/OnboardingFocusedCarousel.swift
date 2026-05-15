import SwiftUI

/// Center-mode infinite sliding carousel.
/// - 사진들이 좌측으로 등속 슬라이드(`cycleDuration`마다 unitWidth 만큼).
/// - 각 사진의 사이즈는 화면 정중앙(center slot)과의 거리에 따라 보간:
///   거리 0 → scale 1.0, 거리 ≥ unitWidth → scale `sideScale`(0.8).
/// - 한 패턴(`imageNames.count` 칸) 진행 후 시간 modulo로 instant reset → 화면 밖에서만 wrap.
/// - `isAnimating == false`이면 첫 frame(시작 시점) 정적 렌더링 (스냅샷용).
struct OnboardingFocusedCarousel: View {
    let imageNames: [String]
    var centerWidthRatio: CGFloat = 0.62
    var sideScale: CGFloat = 0.8
    var spacing: CGFloat = 12
    /// 한 사이클의 슬라이드 진행 시간(unitWidth 만큼 이동).
    var slideDuration: Double = 0.8
    /// 사진이 center에 도달한 직후 정지하는 시간.
    var holdDuration: Double = 2.0
    var isAnimating: Bool = true

    private var cycleDuration: Double { slideDuration + holdDuration }

    /// 화면 밖 양쪽으로 충분한 여유를 두기 위한 사진 반복 횟수.
    private let repeatCount = 9

    @State private var startDate: Date = .now

    var body: some View {
        GeometryReader { proxy in
            let containerWidth = proxy.size.width
            let centerWidth = containerWidth * centerWidthRatio
            let unitWidth = centerWidth + spacing
            let totalImages = max(imageNames.count, 1)
            // 시각 정중앙에 imageIndex=1 사진을 처음 위치시키기 위해 expanded 배열 중앙쯤 선택.
            let firstCenterExpandedIndex = totalImages * (repeatCount / 2) + 1
            let firstCenterBaseX = CGFloat(firstCenterExpandedIndex) * unitWidth + centerWidth / 2
            let initialShift = containerWidth / 2 - firstCenterBaseX

            if isAnimating, totalImages > 1 {
                TimelineView(.animation) { context in
                    let elapsed = context.date.timeIntervalSince(startDate)
                    // 한 패턴 진행 후 modulo → instant reset (시각적 변화 없음).
                    let patternSeconds = cycleDuration * Double(totalImages)
                    let phaseInPattern = elapsed.truncatingRemainder(dividingBy: patternSeconds)
                    let cycleIndex = floor(phaseInPattern / cycleDuration)
                    let phaseInCycle = phaseInPattern - cycleIndex * cycleDuration
                    // slide → hold 분리. hold 동안엔 1.0(=cycle 완료) 유지 → center 도달 후 정지.
                    let slideProgress = min(phaseInCycle / slideDuration, 1)
                    let totalProgress = cycleIndex + slideProgress
                    let animatedOffset = -CGFloat(totalProgress) * unitWidth
                    content(
                        containerWidth: containerWidth,
                        centerWidth: centerWidth,
                        unitWidth: unitWidth,
                        totalImages: totalImages,
                        initialShift: initialShift,
                        animatedOffset: animatedOffset
                    )
                }
            } else {
                content(
                    containerWidth: containerWidth,
                    centerWidth: centerWidth,
                    unitWidth: unitWidth,
                    totalImages: totalImages,
                    initialShift: initialShift,
                    animatedOffset: 0
                )
            }
        }
        .aspectRatio(1 / centerWidthRatio, contentMode: .fit)
    }

    private func content(
        containerWidth: CGFloat,
        centerWidth: CGFloat,
        unitWidth: CGFloat,
        totalImages: Int,
        initialShift: CGFloat,
        animatedOffset: CGFloat
    ) -> some View {
        ZStack {
            ForEach(0..<(totalImages * repeatCount), id: \.self) { expandedIndex in
                let imageIndex = expandedIndex % totalImages
                let baseX = CGFloat(expandedIndex) * unitWidth + centerWidth / 2
                let currentX = baseX + initialShift + animatedOffset
                let distFromCenter = abs(currentX - containerWidth / 2)
                let normalized = min(distFromCenter / unitWidth, 1)
                let scale = 1 - normalized * (1 - sideScale)

                Image(imageNames[imageIndex])
                    .resizable()
                    .scaledToFill()
                    .frame(width: centerWidth, height: centerWidth)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .scaleEffect(scale)
                    .position(x: currentX, y: centerWidth / 2)
            }
        }
        .frame(width: containerWidth, height: centerWidth)
    }
}

#Preview("Static") {
    OnboardingFocusedCarousel(
        imageNames: ["onboarding_2_pic_0", "onboarding_2_pic_1", "onboarding_2_pic_2"],
        isAnimating: false
    )
    .frame(height: 320)
    .background(Color.black)
}

#Preview("Animating") {
    OnboardingFocusedCarousel(
        imageNames: ["onboarding_3_pic_0", "onboarding_3_pic_1", "onboarding_3_pic_2"]
    )
    .frame(height: 320)
    .background(Color.black)
}
