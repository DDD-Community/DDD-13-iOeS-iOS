import SwiftUI

/// 온보딩 컨테이너.
/// - PICKFLOW 워드마크(좌상단)와 하단 패널(인디케이터·CTA·타이틀·서브타이틀)은 위치 고정
/// - 일러스트 영역은 HStack 오프셋 기반 커스텀 페이저로 가로 페이지 전환
/// - **드래그 제스처는 화면 전체(일러스트 + 패널)에 부착**되어, 패널 영역에서도 위 스크롤뷰처럼 인터랙티브하게 페이지를 끌어올 수 있다.
/// - 릴리스 시 predictedEndTranslation 기준으로 인접 페이지에 스프링 스냅
struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    @State private var dragOffset: CGFloat = 0

    private let snapAnimation: Animation = .interpolatingSpring(stiffness: 220, damping: 24)
    private let swipeMinimumDistance: CGFloat = 8
    private let edgeRubberBand: CGFloat = 0.3

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    HStack(spacing: 0) {
                        ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { _, page in
                            OnboardingIllustration(page: page)
                                .frame(width: geo.size.width)
                        }
                    }
                    .offset(x: pagerOffset(width: geo.size.width))

                    wordmark
                }
                .frame(maxHeight: .infinity)
                .clipped()

                OnboardingPanel(
                    page: viewModel.pages[viewModel.currentIndex],
                    currentIndex: viewModel.currentIndex,
                    pageCount: viewModel.pages.count,
                    onPrimaryTap: { viewModel.finishOnboarding() }
                )
                .animation(.easeInOut(duration: 0.2), value: viewModel.currentIndex)
            }
            .background(OnboardingPalette.panelBackground)
            .ignoresSafeArea(.container, edges: .top)
            .contentShape(Rectangle())
            .simultaneousGesture(makePagerGesture(pageWidth: geo.size.width))
        }
    }

    private func pagerOffset(width: CGFloat) -> CGFloat {
        -CGFloat(viewModel.currentIndex) * width + dragOffset
    }

    private func makePagerGesture(pageWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: swipeMinimumDistance)
            .onChanged { value in
                let proposed = value.translation.width
                let atLeadingEdge = viewModel.currentIndex == 0 && proposed > 0
                let atTrailingEdge = viewModel.currentIndex == viewModel.pages.count - 1 && proposed < 0
                if atLeadingEdge || atTrailingEdge {
                    dragOffset = proposed * edgeRubberBand
                } else {
                    dragOffset = proposed
                }
            }
            .onEnded { value in
                let predicted = value.predictedEndTranslation.width
                let threshold = pageWidth / 4

                var nextIndex = viewModel.currentIndex
                if predicted < -threshold {
                    nextIndex = min(viewModel.currentIndex + 1, viewModel.pages.count - 1)
                } else if predicted > threshold {
                    nextIndex = max(viewModel.currentIndex - 1, 0)
                }

                withAnimation(snapAnimation) {
                    if nextIndex != viewModel.currentIndex {
                        viewModel.setPage(nextIndex)
                    }
                    dragOffset = 0
                }
            }
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
