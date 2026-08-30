import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var pages: [OnboardingPage]
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var isFinished: Bool = false

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
    var primaryButtonTitle: String { isOnLastPage ? "시작하기" : "다음으로" }

    func primaryButtonTapped() {
        if isOnLastPage {
            finishOnboarding()
        } else {
            goToNextPage()
        }
    }

    func goToNextPage() {
        guard currentIndex < pages.count - 1 else { return }
        currentIndex += 1
    }

    func goToPreviousPage() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    func setPage(_ index: Int) {
        let upper = pages.count - 1
        currentIndex = max(0, min(index, upper))
    }

    func finishOnboarding() {
        completionStore.markOnboardingSeen()
        isFinished = true
    }
}
