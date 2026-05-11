import SwiftUI

/// 단일 페이지를 전체 화면으로 합성한 정적 뷰. 스냅샷 테스트 / 디버그 프리뷰용.
/// 실제 앱 launch 시에는 `OnboardingView`가 사용되며, 그쪽은 PICKFLOW 헤더와 CTA를 고정하고 일러스트만 페이지 스크롤한다.
struct OnboardingPageView: View {
    let page: OnboardingPage
    let currentIndex: Int
    let pageCount: Int
    let onPrimaryTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                OnboardingIllustration(page: page)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                wordmark
            }

            OnboardingPanel(
                page: page,
                currentIndex: currentIndex,
                pageCount: pageCount,
                onPrimaryTap: onPrimaryTap
            )
        }
        .background(OnboardingPalette.panelBackground)
    }

    private var wordmark: some View {
        Text("PICKFLOW")
            .font(.custom("Rambla-Bold", size: 28))
            .tracking(-0.056)
            .lineSpacing(1.11)
            .foregroundStyle(OnboardingPalette.title)
            .padding(.leading, 20)
            .padding(.top, 16)
    }
}
