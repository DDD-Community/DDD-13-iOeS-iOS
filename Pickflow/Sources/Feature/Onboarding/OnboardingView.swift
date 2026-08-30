import SwiftUI

/// 온보딩 컨테이너.
/// - PICKFLOW 워드마크(좌상단)와 하단 패널(인디케이터·CTA·타이틀·서브타이틀)은 위치 고정
/// - 일러스트 영역은 HStack 오프셋 기반 커스텀 페이저로 가로 페이지 전환
/// - **드래그 제스처는 화면 전체(일러스트 + 패널)에 부착**되어, 패널 영역에서도 위 스크롤뷰처럼 인터랙티브하게 페이지를 끌어올 수 있다.
/// - 릴리스 시 predictedEndTranslation 기준으로 인접 페이지에 스프링 스냅
struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel

    /// 온보딩 완료 시 상위(`AppRootView`)로 전파되는 콜백.
    private let onOnboardingFinished: () -> Void

    /// Step 2/3 focused carousel의 자동 슬라이딩 활성 여부. 테스트(스냅샷)에서 false로 정적 캡쳐.
    var isCarouselAnimating: Bool = true

    @State private var dragOffset: CGFloat = 0
    @State private var pagerSize: CGSize = .zero

    private let snapAnimation: Animation = .interpolatingSpring(stiffness: 220, damping: 24)
    private let swipeMinimumDistance: CGFloat = 8
    private let edgeRubberBand: CGFloat = 0.3

    init(
        viewModel: OnboardingViewModel,
        isCarouselAnimating: Bool = true,
        onOnboardingFinished: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.isCarouselAnimating = isCarouselAnimating
        self.onOnboardingFinished = onOnboardingFinished
    }

    var body: some View {
        VStack(spacing: 0) {
            illustrationPager
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea(edges: .top)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: PagerSizeKey.self,
                            value: geo.size
                        )
                    }
                )
                .onPreferenceChange(PagerSizeKey.self) { pagerSize = $0 }

            OnboardingPanel(
                page: viewModel.pages[viewModel.currentIndex],
                currentIndex: viewModel.currentIndex,
                pageCount: viewModel.pages.count,
                primaryButtonTitle: viewModel.primaryButtonTitle,
                onPrimaryTap: viewModel.primaryButtonTapped
            )
            .animation(.easeInOut(duration: 0.2), value: viewModel.currentIndex)
        }
        .background(OnboardingPalette.panelBackground)
        .contentShape(Rectangle())
        .simultaneousGesture(makePagerGesture(pageWidth: pagerSize.width))
        .overlay(alignment: .topLeading) {
            PickflowWorkMarkLogo()
            .padding(.top, 12)
            .padding(.leading, 16)
        }
        .onChange(of: viewModel.isFinished) { _, isFinished in
            if isFinished {
                onOnboardingFinished()
            }
        }
    }

    private var illustrationPager: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { _, page in
                    OnboardingIllustration(
                        page: page,
                        isCarouselAnimating: isCarouselAnimating,
                        toastText: page.id == 1 ? viewModel.toast : page.toastText
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.toast)
                }
            }
            .offset(x: pagerOffset(width: geo.size.width))
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
}

#Preview {
    OnboardingView(
        viewModel: OnboardingViewModel(completionStore: UserDefaultsOnboardingCompletionStore())
    )
}

private struct PagerSizeKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
