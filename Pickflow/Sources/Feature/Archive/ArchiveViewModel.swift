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

        /// 이미 화면에 표시할 결과가 확정된 상태(로딩 스켈레톤을 다시 띄울 필요 없음).
        var hasData: Bool {
            switch self {
            case .loaded, .empty: true
            case .signedOut, .loading, .failed: false
            }
        }
    }

    enum MySpotsLoadState: Equatable {
        case loading
        case loaded(items: [MySpotListItem], hasNext: Bool)
        case empty
        case failed(String)

        /// 이미 화면에 표시할 결과가 확정된 상태(로딩 스켈레톤을 다시 띄울 필요 없음).
        var hasData: Bool {
            switch self {
            case .loaded, .empty: true
            case .loading, .failed: false
            }
        }
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
    @Published private(set) var isSpotOpenGuidePresented: Bool = false

    private let archiveService: ArchiveServiceProtocol
    private let bookmarkService: BookmarkServiceProtocol
    private let authService: AuthServiceProtocol
    private let socialLoginService: SocialLoginServiceProtocol
    private let locationService: LocationServiceProtocol
    private let newFeatureGuideStore: NewFeatureGuideStore

    private var currentPage: Int = 0
    private var hasNext: Bool = false
    private var mySpotsCurrentPage: Int = 0
    private var mySpotsHasNext: Bool = false
    private var currentCoordinate: Coordinate?
    private var currentUserGuideKey: String?
    nonisolated(unsafe) private var notificationObservers: [NSObjectProtocol] = []

    init(
        archiveService: ArchiveServiceProtocol,
        bookmarkService: BookmarkServiceProtocol,
        authService: AuthServiceProtocol,
        socialLoginService: SocialLoginServiceProtocol,
        locationService: LocationServiceProtocol,
        newFeatureGuideStore: NewFeatureGuideStore = getNewFeatureGuideStore()
    ) {
        self.archiveService = archiveService
        self.bookmarkService = bookmarkService
        self.authService = authService
        self.socialLoginService = socialLoginService
        self.locationService = locationService
        self.newFeatureGuideStore = newFeatureGuideStore
        setupNotificationObservers()
    }

    deinit {
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    private func setupNotificationObservers() {
        // 스팟 상세 등 다른 화면에서 북마크가 변경되면 저장된 스팟 목록을 조용히 다시 불러온다.
        let bookmarkObserver = NotificationCenter.default.addObserver(
            forName: .spotBookmarkDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // 보관함 화면 자체에서 해제한 경우는 이미 반영됐으므로 중복 재조회 방지
            let isSelfPost = (notification.object as AnyObject?) === self
            Task { @MainActor [weak self] in
                guard let self, !isSelfPost else { return }
                guard self.state != .signedOut else { return }
                await self.fetchArchive(silent: true)
            }
        }
        // 스팟 등록 완료 시 나만의 스팟 목록을 조용히 갱신한다.
        // (보관함 밖/안 어디서 등록하든 반영 — 빈 상태 placeholder 등록 후 pop 시에도 갱신)
        let registerObserver = NotificationCenter.default.addObserver(
            forName: .spotDidRegister,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.state != .signedOut else { return }
                await self.fetchMySpots(silent: true)
            }
        }
        notificationObservers = [bookmarkObserver, registerObserver]
    }

    func onAppear() async {
        let authState = await authService.currentAuthState()
        guard case let .signedIn(token) = authState else {
            state = .signedOut
            currentUserGuideKey = nil
            return
        }
        currentUserGuideKey = token.newFeatureGuideUserKey
        refreshFeatureConfigAndEvaluateSpotOpenGuide()
        // 이미 표시할 데이터가 있으면(탭 재진입 등) 로딩 스켈레톤 없이 조용히 갱신해
        // 화면이 매번 깜빡이며 리프레시되는 현상을 막는다. (@StateObject 라 이전 상태 유지)
        // 최초 진입·재시도·로그인 직후엔 데이터가 없으므로 로딩을 노출한다.
        let archiveSilent = state.hasData
        let mySpotsSilent = mySpotsState.hasData
        let hadLocation = locationService.lastKnownLocation != nil
        currentCoordinate = locationService.lastKnownLocation
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchArchiveInfo() }
            group.addTask { await self.fetchArchive(silent: archiveSilent) }
            group.addTask { await self.fetchMySpots(silent: mySpotsSilent) }
        }
        // 위치 없이 로드했다면, 위치 들어오는 즉시 거리 포함해 조용히 재조회
        if !hadLocation {
            if let coord = try? await locationService.currentLocation() {
                currentCoordinate = coord
                await fetchArchive(silent: true)
                await fetchMySpots(silent: true)
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
        evaluateSpotOpenGuidePresentation()
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
            showToast("보관함 이름이 변경되었습니다.")
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

    func dismissSpotOpenGuide() {
        guard let currentUserGuideKey else {
            isSpotOpenGuidePresented = false
            return
        }
        newFeatureGuideStore.markSpotOpenGuideSeen(userKey: currentUserGuideKey)
        isSpotOpenGuidePresented = false
    }

    func spotOpenGuidePrimaryTapped() -> Int64? {
        let spotId = firstMySpotId
        dismissSpotOpenGuide()
        return spotId
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
            NotificationCenter.default.post(name: .spotBookmarkDidChange, object: self)
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

    /// - Parameter silent: true면 로딩/실패 상태로 전환하지 않고 성공 시에만 목록을 교체한다.
    ///   (탭 재진입·백그라운드 갱신에서 화면 깜빡임을 없애기 위함)
    private func fetchArchive(silent: Bool = false) async {
        if !silent {
            state = .loading
            currentPage = 0
            hasNext = false
        }

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
            guard !silent else { return }
            state = .failed(e.message)
            e.post()
        } catch {
            guard !silent else { return }
            state = .failed(error.localizedDescription)
        }
    }

    private func fetchMySpots(silent: Bool = false) async {
        if !silent {
            mySpotsState = .loading
            mySpotsCurrentPage = 0
            mySpotsHasNext = false
        }

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
            evaluateSpotOpenGuidePresentation()
        } catch {
            guard !silent else { return }
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
            evaluateSpotOpenGuidePresentation()
        } catch {
            toast = "다음 페이지를 불러오지 못했어요."
        }
    }

    private var firstMySpotId: Int64? {
        guard case let .loaded(items, _) = mySpotsState else { return nil }
        return items.first?.spotId
    }

    private func evaluateSpotOpenGuidePresentation(now: Date = Date()) {
        guard selectedTab == .mySpots else { return }
        guard !isSpotOpenGuidePresented else { return }
        guard firstMySpotId != nil else { return }
        guard let currentUserGuideKey else { return }
        isSpotOpenGuidePresented = newFeatureGuideStore.shouldShowSpotOpenGuide(
            userKey: currentUserGuideKey,
            now: now
        )
    }

    private func refreshFeatureConfigAndEvaluateSpotOpenGuide() {
        evaluateSpotOpenGuidePresentation()
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.newFeatureGuideStore.refreshFeatureConfig()
            self.evaluateSpotOpenGuidePresentation()
        }
    }
}
