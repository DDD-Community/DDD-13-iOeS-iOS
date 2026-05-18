import Foundation

enum ArchiveTab: Hashable, CaseIterable, Equatable {
    case savedSpots
    case mySpots

    var title: String {
        switch self {
        case .savedSpots: "저장된 스팟"
        case .mySpots: "나만의 스팟"
        }
    }
}

@MainActor
final class ArchiveViewModel: ObservableObject {
    enum LoadState: Equatable {
        case signedOut
        case loading
        case loaded(items: [SpotListItem], hasNext: Bool)
        case empty
        case failed(String)
    }

    @Published private(set) var state: LoadState = .loading
    @Published private(set) var selectedTab: ArchiveTab = .savedSpots
    @Published private(set) var isLoadingNextPage: Bool = false
    @Published private(set) var isLoginLoading: Bool = false
    @Published private(set) var loginError: String?
    @Published var toast: String?

    private let archiveService: ArchiveServiceProtocol
    private let bookmarkService: BookmarkServiceProtocol
    private let authService: AuthServiceProtocol
    private let socialLoginService: SocialLoginServiceProtocol

    private var currentPage: Int = 0
    private var hasNext: Bool = false

    init(
        archiveService: ArchiveServiceProtocol,
        bookmarkService: BookmarkServiceProtocol,
        authService: AuthServiceProtocol,
        socialLoginService: SocialLoginServiceProtocol
    ) {
        self.archiveService = archiveService
        self.bookmarkService = bookmarkService
        self.authService = authService
        self.socialLoginService = socialLoginService
    }

    func onAppear() async {
        let authState = await authService.currentAuthState()
        guard case .signedIn = authState else {
            state = .signedOut
            return
        }
        await fetchArchive()
    }

    func signInWithKakao() async {
        guard !isLoginLoading else { return }
        isLoginLoading = true
        loginError = nil
        do {
            try await socialLoginService.signInWithKakao()
            await onAppear()
        } catch {
            loginError = error.localizedDescription
        }
        isLoginLoading = false
    }

    func signInWithApple() async {
        guard !isLoginLoading else { return }
        isLoginLoading = true
        loginError = nil
        do {
            try await socialLoginService.signInWithApple()
            await onAppear()
        } catch {
            loginError = error.localizedDescription
        }
        isLoginLoading = false
    }

    func tabChanged(_ tab: ArchiveTab) {
        selectedTab = tab
    }

    func loadNextPageIfNeeded(currentItem: SpotListItem) async {
        guard case let .loaded(items, hasNext) = state, hasNext, !isLoadingNextPage else { return }
        let triggerIndex = max(0, items.count - 3)
        guard let index = items.firstIndex(where: { $0.id == currentItem.id }),
              index >= triggerIndex else { return }

        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        let nextPage = currentPage + 1
        do {
            let response = try await archiveService.fetchArchive(page: nextPage)
            currentPage = response.page
            self.hasNext = response.hasNext
            state = .loaded(items: items + response.spots, hasNext: response.hasNext)
        } catch {
            toast = "다음 페이지를 불러오지 못했어요."
        }
    }

    func bookmarkTapped(_ spotId: Int64) async {
        guard case var .loaded(items, hasNext) = state else { return }
        guard let removedIndex = items.firstIndex(where: { $0.spotId == spotId }) else { return }
        let removedItem = items[removedIndex]

        items.remove(at: removedIndex)
        state = items.isEmpty ? .empty : .loaded(items: items, hasNext: hasNext)

        do {
            try await bookmarkService.deleteBookmark(spotId: spotId)
        } catch {
            var restored = items
            restored.insert(removedItem, at: min(removedIndex, restored.count))
            state = .loaded(items: restored, hasNext: hasNext)
            toast = "북마크 해제에 실패했어요."
        }
    }

    // MARK: - Private

    private func fetchArchive() async {
        state = .loading
        currentPage = 0
        hasNext = false

        do {
            let response = try await archiveService.fetchArchive(page: 0)
            currentPage = response.page
            hasNext = response.hasNext
            state = response.spots.isEmpty
                ? .empty
                : .loaded(items: response.spots, hasNext: response.hasNext)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
