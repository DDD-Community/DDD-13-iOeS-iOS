import CoreLocation
import Foundation

@MainActor
final class SpotListViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(items: [SpotListItem], hasNext: Bool)
        case empty
        case failed(String)
    }

    @Published private(set) var state: LoadState = .idle
    /// 카테고리 필터(다중선택). 비어 있으면 전체.
    @Published private(set) var selectedThemes: Set<SpotTheme> = []
    @Published private(set) var sort: SpotListSort = .distance
    @Published var showLoginPrompt: Bool = false
    @Published var showLocationPermissionPrompt: Bool = false
    @Published var toast: String?
    @Published private(set) var bookmarkStates: [Int64: Bool] = [:]
    @Published private(set) var isLoadingNextPage: Bool = false

    private let spotListService: SpotListServiceProtocol
    private let bookmarkService: BookmarkServiceProtocol
    private let locationService: LocationServiceProtocol
    private let tokenStore: TokenStoreProtocol

    private var currentPage: Int = 0
    private var hasNext: Bool = false
    private var currentCoordinate: Coordinate?
    private var hasInitializedSort: Bool = false
    nonisolated(unsafe) private var likeObserver: NSObjectProtocol?
    nonisolated(unsafe) private var bookmarkObserver: NSObjectProtocol?

    init(
        spotListService: SpotListServiceProtocol,
        bookmarkService: BookmarkServiceProtocol,
        locationService: LocationServiceProtocol,
        tokenStore: TokenStoreProtocol,
        initialThemes: Set<SpotTheme> = []
    ) {
        self.spotListService = spotListService
        self.bookmarkService = bookmarkService
        self.locationService = locationService
        self.tokenStore = tokenStore
        self.selectedThemes = initialThemes
        setupLikeObserver()
        setupBookmarkObserver()
    }

    deinit {
        likeObserver.map(NotificationCenter.default.removeObserver)
        bookmarkObserver.map(NotificationCenter.default.removeObserver)
    }

    /// 스팟 상세에서 추천을 바꾸면, 여기서는 전체 재조회 대신 해당 아이템만 갱신한다.
    /// 전체 재조회는 로딩 스피너와 스크롤/정렬 초기화를 동반해 되돌아올 때마다 화면이 튄다.
    private func setupLikeObserver() {
        likeObserver = NotificationCenter.default.addObserver(
            forName: .spotLikeDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let change = notification.object as? SpotLikeChange else { return }
            self?.applyLikeChange(change)
        }
    }

    private func applyLikeChange(_ change: SpotLikeChange) {
        guard case let .loaded(items, hasNext) = state else { return }
        guard let index = items.firstIndex(where: { $0.spotId == change.spotId }) else { return }
        var updated = items
        updated[index].likeCount = change.likeCount
        updated[index].isLiked = change.isLiked
        state = .loaded(items: updated, hasNext: hasNext)
    }

    /// 상세 화면 등 다른 곳에서 북마크를 바꾸면, 보관함처럼 전체를 다시 불러오는 대신
    /// `bookmarkStates` 만 갱신한다. 리스트는 북마크 여부와 무관하게 아이템이 그대로 남으니
    /// 필드 갱신만으로 충분하다(자기 자신이 보낸 알림도 다시 받지만 같은 값을 대입할 뿐이라 무해하다).
    private func setupBookmarkObserver() {
        bookmarkObserver = NotificationCenter.default.addObserver(
            forName: .spotBookmarkDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let change = notification.object as? SpotBookmarkChange else { return }
            self?.bookmarkStates[change.spotId] = change.isBookmarked
        }
    }

    func onAppear() async {
        await reload()
    }

    /// 칩 탭 토글. 이미 선택돼 있으면 해제한다.
    func themeTapped(_ theme: SpotTheme) async {
        if selectedThemes.contains(theme) {
            selectedThemes.remove(theme)
        } else {
            selectedThemes.insert(theme)
        }
        await reload()
    }

    /// 외부(HomeMapView 의 필터 칩 등)에서 카테고리 변경을 통보받았을 때 호출. 동일하면 no-op.
    func themeSynced(_ themes: Set<SpotTheme>) async {
        guard selectedThemes != themes else { return }
        selectedThemes = themes
        await reload()
    }

    func sortChanged(_ sort: SpotListSort) async {
        if sort == .distance, !hasLocationPermission {
            switch locationService.authorizationStatus() {
            case .notDetermined:
                locationService.requestAuthorization()
            default:
                showLocationPermissionPrompt = true
            }
            return
        }
        guard self.sort != sort else { return }
        self.sort = sort
        await reload()
    }

    func loadNextPageIfNeeded(currentItem: SpotListItem) async {
        guard case let .loaded(items, hasNext) = state, hasNext, !isLoadingNextPage else { return }
        let triggerIndex = max(0, items.count - 3)
        guard let index = items.firstIndex(where: { $0.id == currentItem.id }), index >= triggerIndex else {
            return
        }

        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        let nextPage = currentPage + 1
        do {
            let response = try await spotListService.fetchSpots(
                page: nextPage,
                themes: selectedThemes,
                sort: sort,
                latitude: currentCoordinate?.latitude,
                longitude: currentCoordinate?.longitude
            )
            currentPage = response.page
            self.hasNext = response.hasNext
            let merged = items + response.spots
            seedBookmarkStates(response.spots)
            state = .loaded(items: merged, hasNext: response.hasNext)
        } catch let e as APIError {
            e.post()
        } catch {
            toast = "다음 페이지를 불러오지 못했어요."
        }
    }

    func bookmarkTapped(_ spotId: Int64) async {
        guard (try? tokenStore.load()) != nil else {
            showLoginPrompt = true
            return
        }

        let wasBookmarked = bookmarkStates[spotId] ?? false
        bookmarkStates[spotId] = !wasBookmarked

        do {
            if wasBookmarked {
                try await bookmarkService.deleteBookmark(spotId: spotId)
            } else {
                try await bookmarkService.addBookmark(spotId: spotId)
            }
            NotificationCenter.default.post(
                name: .spotBookmarkDidChange,
                object: SpotBookmarkChange(spotId: spotId, isBookmarked: !wasBookmarked)
            )
        } catch BookmarkError.alreadyBookmarked {
            bookmarkStates[spotId] = true
            NotificationCenter.default.post(
                name: .spotBookmarkDidChange,
                object: SpotBookmarkChange(spotId: spotId, isBookmarked: true)
            )
        } catch let e as APIError {
            bookmarkStates[spotId] = wasBookmarked
            e.post()
        } catch {
            bookmarkStates[spotId] = wasBookmarked
            toast = "북마크 변경에 실패했어요."
        }
    }

    func isBookmarked(_ spotId: Int64) -> Bool {
        bookmarkStates[spotId] ?? false
    }

    /// 서버에서 받은 item.isBookmarked 로 로컬 상태 시드. 이미 사용자가 토글한 키는 덮어쓰지 않는다.
    private func seedBookmarkStates(_ spots: [SpotListItem]) {
        for spot in spots where bookmarkStates[spot.spotId] == nil {
            bookmarkStates[spot.spotId] = spot.isBookmarked
        }
    }

    // MARK: - Private

    private var hasLocationPermission: Bool {
        switch locationService.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse: true
        default: false
        }
    }

    private func reload() async {
        let permitted = hasLocationPermission
        if !hasInitializedSort {
            hasInitializedSort = true
            if !permitted {
                sort = .recommended
            }
        }
        if locationService.authorizationStatus() == .notDetermined {
            locationService.requestAuthorization()
        }

        state = .loading
        currentPage = 0
        hasNext = false

        let coordinate = permitted ? try? await locationService.currentLocation() : nil
        currentCoordinate = coordinate

        do {
            let response = try await spotListService.fetchSpots(
                page: 0,
                themes: selectedThemes,
                sort: sort,
                latitude: coordinate?.latitude,
                longitude: coordinate?.longitude
            )
            currentPage = response.page
            hasNext = response.hasNext
            if response.spots.isEmpty {
                state = .empty
            } else {
                seedBookmarkStates(response.spots)
                state = .loaded(items: response.spots, hasNext: response.hasNext)
            }
        } catch let e as APIError {
            state = .failed(e.message)
            e.post()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
