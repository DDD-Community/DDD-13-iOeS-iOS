import SwiftUI

/// Center-mode infinite carousel의 변형. 3-슬롯(좌/중앙/우) 고정 위치에 3장의 사진을 배치하고,
/// 일정 주기로 사진과 슬롯의 매핑을 회전시킨다.
/// - 슬롯 위치/사이즈는 고정. 가운데(슬롯 1) = 100%, 좌우(슬롯 0/2) = 80% (sideScale).
/// - 매 사이클마다 모든 사진이 한 칸씩 이동(scale+fade 전환). 슬라이드 이동은 없다.
/// - `isAnimating == false`이면 step=0 정적 상태로 렌더링 (스냅샷용).
struct OnboardingFocusedCarousel: View {
    let imageNames: [String]
    var centerWidthRatio: CGFloat = 0.62
    var sideScale: CGFloat = 0.8
    var spacing: CGFloat = 12
    /// 한 사이클(머무름 + 전환) 시간.
    /// 머무름 시간 = `cycleDuration - transitionDuration`.
    var cycleDuration: Double = 2.6
    var transitionDuration: Double = 0.6
    var isAnimating: Bool = true

    @State private var step: Int = 0

    var body: some View {
        GeometryReader { proxy in
            let containerWidth = proxy.size.width
            let centerWidth = containerWidth * centerWidthRatio
            let sideWidth = centerWidth * sideScale
            let totalImages = max(imageNames.count, 1)

            ZStack {
                ForEach(0..<totalImages, id: \.self) { imageIndex in
                    let slot = (imageIndex + step) % totalImages
                    let prevSlot = (imageIndex + step - 1 + totalImages) % totalImages
                    let isCenter = slot == 1
                    // 슬롯 마지막 → 0 으로 이동(wrap)하는 사진은 애니메이션 없이 즉시 점프.
                    let isWrapping = prevSlot == totalImages - 1 && slot == 0
                    Image(imageNames[imageIndex])
                        .resizable()
                        .scaledToFill()
                        .frame(width: centerWidth, height: centerWidth)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .scaleEffect(isCenter ? 1 : sideScale)
                        .position(
                            x: slotCenterX(
                                slot: slot,
                                containerWidth: containerWidth,
                                centerWidth: centerWidth,
                                sideWidth: sideWidth
                            ),
                            y: centerWidth / 2
                        )
                        .zIndex(isCenter ? 1 : 0)
                        .animation(
                            isWrapping ? nil : .easeInOut(duration: transitionDuration),
                            value: step
                        )
                }
            }
            .frame(width: containerWidth, height: centerWidth)
            .onAppear {
                guard isAnimating, totalImages > 1 else { return }
                Task { @MainActor in
                    while !Task.isCancelled {
                        try? await Task.sleep(nanoseconds: UInt64(cycleDuration * 1_000_000_000))
                        step += 1
                    }
                }
            }
        }
        .aspectRatio(1 / centerWidthRatio, contentMode: .fit)
    }

    private func slotCenterX(
        slot: Int,
        containerWidth: CGFloat,
        centerWidth: CGFloat,
        sideWidth: CGFloat
    ) -> CGFloat {
        let middle = containerWidth / 2
        let halfCenter = centerWidth / 2
        let halfSide = sideWidth / 2
        switch slot {
        case 0: return middle - halfCenter - spacing - halfSide
        case 1: return middle
        case 2: return middle + halfCenter + spacing + halfSide
        default: return middle
        }
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
