import SwiftUI

/// 페이지별 일러스트. 레이아웃은 `OnboardingPage.layout` switch로 분기.
/// - `.topAlignedImage` (Step 0): 단일 이미지 상단 정렬, safe area 침범.
/// - `.bottomAlignedImage` (Step 1): 단일 이미지 하단 정렬 + 좌우 패딩 + 상단 토스트 슬롯.
/// - `.moodCarousel` (Step 2/3): mood 헤더(`OnboardingMoodHeaderView`) + focused carousel.
/// 상단 `PICKFLOW` 워드마크는 `OnboardingView`가 고정으로 렌더한다.
struct OnboardingIllustration: View {
    let page: OnboardingPage
    var isCarouselAnimating: Bool = true
    /// Step 1 이미지 상단에 띄울 토스트 텍스트. nil이면 비표시.
    var toastText: String? = nil

    var body: some View {
        ZStack {
            backgroundLayer
            content
        }
        .clipped()
    }

    @ViewBuilder
    private var content: some View {
        switch page.layout {
        case .topAlignedImage: topAlignedImage
        case .bottomAlignedImage: bottomAlignedImage
        case .moodCarousel: moodAndCarousel
        }
    }

    /// Step 0/1은 그라데이션 단독, Step 2/3은 panel base 위에 그라데이션 50% opacity.
    @ViewBuilder
    private var backgroundLayer: some View {
        switch page.layout {
        case .topAlignedImage, .bottomAlignedImage:
            page.gradient.linearGradient
                .ignoresSafeArea()
        case .moodCarousel:
            ZStack {
                OnboardingPalette.panelBackground
                    .ignoresSafeArea()
                page.gradient.linearGradient
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Layouts

    private var topAlignedImage: some View {
        VStack(spacing: 0) {
            phoneImage
                .padding(.horizontal, 60)
            Spacer(minLength: 0)
        }
        .ignoresSafeArea(edges: .top)
    }

    private var bottomAlignedImage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 60)
            phoneImage
                .padding(.horizontal, 60)
                .frame(maxWidth: .infinity, alignment: .bottom)
                .background(alignment: .top) {
                    if let toastText {
                        OnboardingToast(text: toastText)
                            .offset(y: -90)
                            .transition(.offset(y: 180).combined(with: .opacity))
                    }
                }
        }
    }

    private var moodAndCarousel: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(spacing: 20) {
                if let header = page.moodHeader {
                    OnboardingMoodHeaderView(header: header)
                }
                OnboardingFocusedCarousel(
                    imageNames: page.carouselImageNames,
                    isAnimating: isCarouselAnimating
                )
            }
            .padding(.bottom, 24)
        }
    }

    private var phoneImage: some View {
        Image(page.imageName)
            .resizable()
            .scaledToFit()
            .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 10)
    }
}

#Preview("Step 0") {
    OnboardingIllustration(page: OnboardingPage.defaultPages[0])
}

#Preview("Step 1 (with toast)") {
    OnboardingIllustration(
        page: OnboardingPage.defaultPages[1],
        toastText: "나만의 스팟이 등록되었어요!"
    )
}

#Preview("Step 2 (mood + carousel)") {
    OnboardingIllustration(
        page: OnboardingPage.defaultPages[2],
        isCarouselAnimating: false
    )
}

#Preview("Step 3 (mood + carousel)") {
    OnboardingIllustration(
        page: OnboardingPage.defaultPages[3],
        isCarouselAnimating: false
    )
}
