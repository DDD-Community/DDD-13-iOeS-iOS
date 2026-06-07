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

    enum MySpotsLoadState: Equatable {
        case loading
        case loaded(items: [MySpotListItem], hasNext: Bool)
        case empty
        case failed(String)
    }

    @Published private(set) var state: LoadState = .loading
    @Published private(set) var mySpotsState: MySpotsLoadState = .loading
    @Published private(set) var selectedTab: ArchiveTab = .savedSpots
    @Published private(set) var isLoadingNextPage: Bool = false
    @Published private(set) var isLoadingNextMySpotsPage: Bool = false
    @Published private(set) var isLoginLoading: Bool = false
    @Published private(set) var loginError: String?
    @Published private(set) var withdrawnAccountInfo: WithdrawnAccountInfo?
    @Published private(set) var archiveImageURL: URL?
    @Published var toast: String?
    @Published var archiveName: String = "나의 보관함"
    @Published var coverImageData: Data?

    private let archiveService: ArchiveServiceProtocol
    private let bookmarkService: BookmarkServiceProtocol
    private let authService: AuthServiceProtocol
    private let socialLoginService: SocialLoginServiceProtocol
    private let locationService: LocationServiceProtocol

    private var currentPage: Int = 0
    private var hasNext: Bool = false
    private var mySpotsCurrentPage: Int = 0
    private var mySpotsHasNext: Bool = false
    private var currentCoordinate: Coordinate?

    init(
        archiveService: ArchiveServiceProtocol,
        bookmarkService: BookmarkServiceProtocol,
        authService: AuthServiceProtocol,
        socialLoginService: SocialLoginServiceProtocol,
        locationService: LocationServiceProtocol
    ) {
        self.archiveService = archiveService
        self.bookmarkService = bookmarkService
        self.authService = authService
        self.socialLoginService = socialLoginService
        self.locationService = locationService
    }

    func onAppear() async {
        let authState = await authService.currentAuthState()
        guard case .signedIn = authState else {
            state = .signedOut
            return
        }
        let hadLocation = locationService.lastKnownLocation != nil
        currentCoordinate = locationService.lastKnownLocation
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchArchiveInfo() }
            group.addTask { await self.fetchArchive() }
            group.addTask { await self.fetchMySpots() }
        }
        // 위치 없이 로드했다면, 위치 들어오는 즉시 거리 포함해 재조회
        if !hadLocation {
            if let coord = try? await locationService.currentLocation() {
                currentCoordinate = coord
                await fetchArchive()
                await fetchMySpots()
            }
        }
    }

    func signInWithKakao() async {
        guard !isLoginLoading else { return }
        isLoginLoading = true
        loginError = nil
        do {
            try await socialLoginService.signInWithKakao()
            await onAppear()
        } catch {
            handleSignInError(error)
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
            handleSignInError(error)
        }
        isLoginLoading = false
    }

    /// 로그인 에러 처리. 재가입 필요면 안내 팝업 상태를 설정한다.
    private func handleSignInError(_ error: Error) {
        if let info = RestoreAccountFlow.info(from: error) {
            withdrawnAccountInfo = info
        } else if let e = error as? APIError {
            e.post()
        } else {
            loginError = error.localizedDescription
        }
    }

    func confirmRestore() async {
        guard let info = withdrawnAccountInfo else { return }
        withdrawnAccountInfo = nil
        isLoginLoading = true
        loginError = nil
        do {
            try await RestoreAccountFlow.restore(info, using: socialLoginService)
            await onAppear()
        } catch let e as APIError {
            e.post()
        } catch {
            loginError = error.localizedDescription
        }
        isLoginLoading = false
    }

    func cancelRestore() {
        withdrawnAccountInfo = nil
    }

    func tabChanged(_ tab: ArchiveTab) {
        selectedTab = tab
    }

    func clearLoginError() {
        loginError = nil
    }

    func renameArchive(_ name: String) async {
        let trimmed = String(name.prefix(15))
        guard !trimmed.isEmpty else { return }
        let previous = archiveName
        archiveName = trimmed
        do {
            let info = try await archiveService.renameArchive(trimmed)
            archiveName = info.archiveName
        } catch let e as APIError {
            archiveName = previous
            e.post()
        } catch {
            archiveName = previous
            showToast("이름 변경에 실패했어요.")
        }
    }

    func updateCoverImage(_ data: Data) async {
        coverImageData = data
        do {
            let info = try await archiveService.uploadArchiveImage(data)
            archiveName = info.archiveName
            if let urlString = info.archiveImageUrl {
                archiveImageURL = URL(string: urlString)
            }
            showToast("커버 이미지가 변경되었습니다.")
        } catch let e as APIError {
            coverImageData = nil
            e.post()
        } catch {
            coverImageData = nil
            showToast("이미지 업로드에 실패했어요.")
        }
    }

    func showToast(_ message: String) {
        toast = message
        Task {
            try? await Task.sleep(for: .seconds(2))
            toast = nil
        }
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
            let response = try await archiveService.fetchSavedSpots(
                page: nextPage,
                latitude: currentCoordinate?.latitude,
                longitude: currentCoordinate?.longitude
            )
            currentPage = response.page
            self.hasNext = response.hasNext
            state = .loaded(items: items + response.spots, hasNext: response.hasNext)
        } catch let e as APIError {
            e.post()
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
            NotificationCenter.default.post(name: .spotBookmarkDidChange, object: nil)
        } catch let e as APIError {
            var restored = items
            restored.insert(removedItem, at: min(removedIndex, restored.count))
            state = .loaded(items: restored, hasNext: hasNext)
            e.post()
        } catch {
            var restored = items
            restored.insert(removedItem, at: min(removedIndex, restored.count))
            state = .loaded(items: restored, hasNext: hasNext)
            toast = "북마크 해제에 실패했어요."
        }
    }

    // MARK: - Debug

    #if DEBUG
    func applyLoadedState(items: [SpotListItem]) {
        state = .loaded(items: items, hasNext: false)
    }

    func applySignedOutState() {
        state = .signedOut
    }

    func applyEmptyState() {
        state = .empty
    }
    #endif

    // MARK: - Private

    private func fetchArchiveInfo() async {
        do {
            let info = try await archiveService.fetchArchiveInfo()
            archiveName = info.archiveName
            if let urlString = info.archiveImageUrl {
                archiveImageURL = URL(string: urlString)
            }
        } catch {
            // 메타데이터 실패는 기본값 유지, 조용히 무시
        }
    }

    private func fetchArchive() async {
        state = .loading
        currentPage = 0
        hasNext = false

        do {
            let response = try await archiveService.fetchSavedSpots(
                page: 0,
                latitude: currentCoordinate?.latitude,
                longitude: currentCoordinate?.longitude
            )
            currentPage = response.page
            hasNext = response.hasNext
            state = response.spots.isEmpty
                ? .empty
                : .loaded(items: response.spots, hasNext: response.hasNext)
        } catch let e as APIError {
            state = .failed(e.message)
            e.post()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func fetchMySpots() async {
        mySpotsState = .loading
        mySpotsCurrentPage = 0
        mySpotsHasNext = false

        do {
            let response = try await archiveService.fetchMySpots(
                page: 0,
                latitude: currentCoordinate?.latitude,
                longitude: currentCoordinate?.longitude
            )
            mySpotsCurrentPage = response.page
            mySpotsHasNext = response.hasNext
            mySpotsState = response.spots.isEmpty
                ? .empty
                : .loaded(items: response.spots, hasNext: response.hasNext)
        } catch {
            mySpotsState = .failed(error.localizedDescription)
        }
    }

    func loadNextMySpotsPageIfNeeded(currentItem: MySpotListItem) async {
        guard case let .loaded(items, hasNext) = mySpotsState, hasNext, !isLoadingNextMySpotsPage else { return }
        let triggerIndex = max(0, items.count - 3)
        guard let index = items.firstIndex(where: { $0.id == currentItem.id }),
              index >= triggerIndex else { return }

        isLoadingNextMySpotsPage = true
        defer { isLoadingNextMySpotsPage = false }

        let nextPage = mySpotsCurrentPage + 1
        do {
            let response = try await archiveService.fetchMySpots(
                page: nextPage,
                latitude: currentCoordinate?.latitude,
                longitude: currentCoordinate?.longitude
            )
            mySpotsCurrentPage = response.page
            mySpotsHasNext = response.hasNext
            mySpotsState = .loaded(items: items + response.spots, hasNext: response.hasNext)
        } catch {
            toast = "다음 페이지를 불러오지 못했어요."
        }
    }
}
