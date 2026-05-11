import SwiftUI

/// 페이지별 일러스트(그라데이션 배경 + 이미지). 상단 `PICKFLOW` 워드마크는 포함하지 않음 — `OnboardingView`가 고정으로 렌더한다.
struct OnboardingIllustration: View {
    let page: OnboardingPage

    var body: some View {
        ZStack {
            LinearGradient(
                stops: page.theme.gradientColos,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .center) {
                Image(page.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, alignment: .bottom)
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    let pages = OnboardingPage.defaultPages
    let index = 3
    OnboardingPageView(page: pages[index], currentIndex: index, pageCount: pages.count) {}
}
