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

    private func presentToast(_ message: String) {
        toast = message
    }
  
  private func dismissToast() {
    toast = nil
  }

    func finishOnboarding() {
        completionStore.markOnboardingSeen()
        isFinished = true
    }
}
