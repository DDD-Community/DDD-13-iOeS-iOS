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
        case locationUnauthorized
    }

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var selectedTheme: SpotTheme?
    @Published private(set) var sort: SpotListSort = .distance
    @Published var showLoginPrompt: Bool = false
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

    init(
        spotListService: SpotListServiceProtocol,
        bookmarkService: BookmarkServiceProtocol,
        locationService: LocationServiceProtocol,
        tokenStore: TokenStoreProtocol,
        initialTheme: SpotTheme? = nil
    ) {
        self.spotListService = spotListService
        self.bookmarkService = bookmarkService
        self.locationService = locationService
        self.tokenStore = tokenStore
        self.selectedTheme = initialTheme
    }

    func onAppear() async {
        await reload()
    }

    func themeTapped(_ theme: SpotTheme) async {
        if selectedTheme == theme {
            selectedTheme = nil
        } else {
            selectedTheme = theme
        }
        await reload()
    }

    /// 외부(HomeMapView 의 mood capsule 등)에서 테마 변경을 통보받았을 때 호출. 동일하면 no-op.
    func themeSynced(_ theme: SpotTheme?) async {
        guard selectedTheme != theme else { return }
        selectedTheme = theme
        await reload()
    }

    func sortChanged(_ sort: SpotListSort) async {
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
                theme: selectedTheme,
                sort: sort,
                latitude: currentCoordinate?.latitude,
                longitude: currentCoordinate?.longitude
            )
            currentPage = response.page
            self.hasNext = response.hasNext
            let merged = items + response.spots
            seedBookmarkStates(response.spots)
            state = .loaded(items: merged, hasNext: response.hasNext)
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
            NotificationCenter.default.post(name: .spotBookmarkDidChange, object: nil)
        } catch BookmarkError.alreadyBookmarked {
            bookmarkStates[spotId] = true
            NotificationCenter.default.post(name: .spotBookmarkDidChange, object: nil)
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

    private func reload() async {
        let status = locationService.authorizationStatus()
        switch status {
        case .denied, .restricted:
            state = .locationUnauthorized
            return
        case .notDetermined:
            locationService.requestAuthorization()
            state = .locationUnauthorized
            return
        default:
            break
        }

        state = .loading
        currentPage = 0
        hasNext = false

        let coordinate = try? await locationService.currentLocation()
        currentCoordinate = coordinate

        do {
            let response = try await spotListService.fetchSpots(
                page: 0,
                theme: selectedTheme,
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
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
