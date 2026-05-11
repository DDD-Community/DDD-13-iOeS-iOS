import SwiftUI

/// 온보딩 컨테이너.
/// 레이아웃 정책:
/// - PICKFLOW 워드마크 (좌상단): **고정** (모든 페이지 동일 위치, 스크롤되지 않음)
/// - 일러스트 영역: TabView 가로 페이지 스크롤 (그라데이션 배경 포함, 페이지 단위로 전환)
/// - 타이틀 / 서브타이틀 / 인디케이터: `viewModel.currentIndex`에 바인딩되어 페이지 전환 시 자연스럽게 갱신
/// - "시작하기" CTA: **고정** (모든 페이지 동일 위치, 모든 페이지에서 완료 처리)
struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                TabView(selection: $viewModel.currentIndex) {
                    ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingIllustration(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()

                wordmark
            }
            .frame(maxHeight: .infinity)

            OnboardingPanel(
                page: viewModel.pages[viewModel.currentIndex],
                currentIndex: viewModel.currentIndex,
                pageCount: viewModel.pages.count,
                onPrimaryTap: { viewModel.finishOnboarding() },
                onSwipeNext: { viewModel.goToNextPage() },
                onSwipePrevious: { viewModel.goToPreviousPage() }
            )
            .animation(.easeInOut(duration: 0.2), value: viewModel.currentIndex)
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

#Preview {
  OnboardingGate(completionStore: getOnboardingCompletionStore()) {
      ContentView()
  }
  
}
