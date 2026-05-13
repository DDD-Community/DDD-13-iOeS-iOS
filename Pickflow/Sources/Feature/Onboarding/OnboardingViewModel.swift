import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var pages: [OnboardingPage]
    @Published var currentIndex: Int = 0
    @Published private(set) var isFinished: Bool = false
    @Published private(set) var toast: String?

    private let completionStore: OnboardingCompletionStore

    init(
        pages: [OnboardingPage] = OnboardingPage.defaultPages,
        completionStore: OnboardingCompletionStore
    ) {
        self.pages = pages
        self.completionStore = completionStore
    }

    var isOnFirstPage: Bool { currentIndex == 0 }
    var isOnLastPage: Bool { currentIndex == pages.count - 1 }

    func goToNextPage() {
        guard currentIndex < pages.count - 1 else { return }
        let previous = currentIndex
        currentIndex += 1
        handlePageTransition(from: previous, to: currentIndex)
    }

    func goToPreviousPage() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    func setPage(_ index: Int) {
        let upper = pages.count - 1
        let clamped = max(0, min(index, upper))
        let previous = currentIndex
        currentIndex = clamped
        handlePageTransition(from: previous, to: clamped)
    }

    private func handlePageTransition(from previous: Int, to next: Int) {
        guard previous == 0 || next == 1 else {
          dismissToast()
          return
        }
        presentToast("나만의 스팟이 등록되었어요!")
    }

    /// 페이지 전환 애니메이션이 끝난 직후 토스트가 등장하도록 지연.
    private static let toastPresentDelay: Double = 0.25

    private func presentToast(_ message: String) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(Self.toastPresentDelay * 1_000_000_000))
            // 지연 후에도 여전히 toast가 의미 있는 페이지(1)일 때만 표시.
            guard currentIndex == 1 else { return }
            toast = message
        }
    }
  
  private func dismissToast() {
    toast = nil
  }

    func finishOnboarding() {
        completionStore.markOnboardingSeen()
        isFinished = true
    }
}
