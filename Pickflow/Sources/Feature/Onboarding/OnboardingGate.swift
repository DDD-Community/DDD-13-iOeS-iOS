import SwiftUI

/// 앱 launch 시 `hasSeenOnboarding` 플래그를 확인해 온보딩 또는 메인 컨텐츠를 분기한다.
struct OnboardingGate<Content: View>: View {
    private let completionStore: OnboardingCompletionStore
    @StateObject private var viewModel: OnboardingViewModel
    @State private var hasSeenOnboarding: Bool
    private let content: () -> Content

    init(
        completionStore: OnboardingCompletionStore,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.completionStore = completionStore
        self.content = content
        _hasSeenOnboarding = State(initialValue: completionStore.hasSeenOnboarding())
        _viewModel = StateObject(
            wrappedValue: OnboardingViewModel(completionStore: completionStore)
        )
    }

    var body: some View {
        Group {
            if hasSeenOnboarding {
                content()
            } else {
                OnboardingView(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: hasSeenOnboarding)
        .onChange(of: viewModel.isFinished) { _, isFinished in
            if isFinished {
                hasSeenOnboarding = true
            }
        }
    }
}
