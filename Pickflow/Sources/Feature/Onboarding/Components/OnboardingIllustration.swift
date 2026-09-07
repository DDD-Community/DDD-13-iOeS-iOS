import SwiftUI

/// 페이지별 일러스트. 그라데이션·UI가 모두 합성된 단일 히어로 이미지를 화면 폭 전체로 상단 정렬한다(Figma `swipe` export).
/// 상단 `PICKFLOW` 워드마크는 `OnboardingView`가 고정으로 렌더한다.
struct OnboardingIllustration: View {
    let page: OnboardingPage
    var isCarouselAnimating: Bool = true

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
        case .fullBleedImage: fullBleedImage
        }
    }

    private var backgroundLayer: some View {
        page.gradient.linearGradient
            .ignoresSafeArea()
    }

    // MARK: - Layouts

    /// 그라데이션·UI가 모두 하나의 이미지로 합성되어 있다(Figma `swipe` 프레임 export).
    /// 원본 에셋 비율(390×500)이 실제 일러스트 영역 높이보다 작을 수 있어, `scaledToFit`으로
    /// 두면 이미지 아래에 배경 그라데이션만 남는 빈 틈이 생긴다. 영역 전체를 채우도록
    /// `scaledToFill` + 상단 정렬 + 클리핑으로 이미지가 항상 패널 상단까지 이어지게 한다.
    private var fullBleedImage: some View {
        GeometryReader { geo in
            Image(page.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                .clipped()
        }
        .ignoresSafeArea(edges: .top)
    }
}

#Preview("Step 0") {
    OnboardingIllustration(page: OnboardingPage.defaultPages[0])
}

#Preview("Step 1") {
    OnboardingIllustration(page: OnboardingPage.defaultPages[1])
}

#Preview("Step 2") {
    OnboardingIllustration(page: OnboardingPage.defaultPages[2])
}

#Preview("Step 3") {
    OnboardingIllustration(page: OnboardingPage.defaultPages[3])
}
