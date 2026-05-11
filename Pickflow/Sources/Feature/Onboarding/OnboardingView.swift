import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        TabView(selection: $viewModel.currentIndex) {
            ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                OnboardingPageView(
                    page: page,
                    currentIndex: viewModel.currentIndex,
                    pageCount: viewModel.pages.count,
                    onPrimaryTap: { viewModel.finishOnboarding() }
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
    }
}
