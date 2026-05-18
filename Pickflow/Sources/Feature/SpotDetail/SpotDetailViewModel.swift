import Foundation

@MainActor
final class SpotDetailViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(SpotDetail)
        case failed(String)
    }

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var isBookmarked = false
    @Published var dismissRequested = false
    @Published var toast: String?
    @Published var isLoginRequired = false
    @Published private(set) var presentationPhase: SpotPresentationPhase = .sheetMedium

    private let spotId: Int64
    private let spotService: SpotServiceProtocol
    private let bookmarkService: BookmarkServiceProtocol
    private let shareIntentService: ShareIntentServiceProtocol
    private let locationService: LocationServiceProtocol
    private let externalAppLauncher: ExternalAppLauncherProtocol
    private let shareSheetPresenter: ShareSheetPresenterProtocol
    private let analyticsLogger: AnalyticsLoggerProtocol
    private let tokenStore: TokenStoreProtocol
    private let deviceIdProvider: @MainActor @Sendable () -> String
    private let clock: @Sendable () -> Date

    init(
        spotId: Int64,
        spotService: SpotServiceProtocol,
        bookmarkService: BookmarkServiceProtocol,
        shareIntentService: ShareIntentServiceProtocol,
        locationService: LocationServiceProtocol,
        externalAppLauncher: ExternalAppLauncherProtocol,
        shareSheetPresenter: ShareSheetPresenterProtocol,
        analyticsLogger: AnalyticsLoggerProtocol = getAnalyticsLogger(),
        tokenStore: TokenStoreProtocol = getTokenStore(),
        deviceIdProvider: @escaping @MainActor @Sendable () -> String,
        clock: @escaping @Sendable () -> Date = Date.init
    ) {
        self.spotId = spotId
        self.spotService = spotService
        self.bookmarkService = bookmarkService
        self.shareIntentService = shareIntentService
        self.locationService = locationService
        self.externalAppLauncher = externalAppLauncher
        self.shareSheetPresenter = shareSheetPresenter
        self.analyticsLogger = analyticsLogger
        self.tokenStore = tokenStore
        self.deviceIdProvider = deviceIdProvider
        self.clock = clock
    }

    func onAppear() async {
        state = .loading

        let coordinate = try? await locationService.currentLocation()

        do {
            let spot = try await spotService.fetchSpotDetail(
                id: spotId,
                latitude: coordinate?.latitude,
                longitude: coordinate?.longitude
            )
            isBookmarked = spot.isBookmarked
            state = .loaded(spot)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func toggleBookmark() async {
        guard case let .loaded(spot) = state else { return }

        guard (try? tokenStore.load()) != nil else {
            isLoginRequired = true
            return
        }

        let previousValue = isBookmarked
        isBookmarked.toggle()

        do {
            if previousValue {
                try await bookmarkService.deleteBookmark(spotId: spot.id)
            } else {
                try await bookmarkService.addBookmark(spotId: spot.id)
            }
        } catch BookmarkError.alreadyBookmarked {
            isBookmarked = true
        } catch {
            isBookmarked = previousValue
            toast = "북마크 변경에 실패했어요."
        }
    }

    func openNaverMapsRoute() {
        guard case let .loaded(spot) = state else { return }
        externalAppLauncher.openNaverMapsRoute(latitude: spot.latitude, longitude: spot.longitude, name: spot.name)
    }

    func share() {
        guard case let .loaded(spot) = state else { return }

        analyticsLogger.log(SpotDetailAnalyticsEvent.shareButtonTap)

        let text = "\(spot.name) - \(spot.comment)\nhttps://pickflow.app/spot/\(spot.id)"
        let deviceId = deviceIdProvider()
        Task {
            try? await shareIntentService.recordIntent(deviceId: deviceId)
        }
        shareSheetPresenter.present(items: [text])
    }

    func reportInvalidInfo() {
        guard case let .loaded(spot) = state else { return }
        Task {
            do {
                try await spotService.reportSpot(id: spot.id, type: .etc, content: "")
                showToast("제보가 접수되었습니다.")
            } catch {
                showToast("제보 접수에 실패했어요.")
            }
        }
    }

    private func showToast(_ message: String) {
        toast = message
        Task {
            try? await Task.sleep(for: .seconds(3))
            toast = nil
        }
    }

    func openSpot() {
        toast = "준비 중이에요."
    }

    func close() {
        dismissRequested = true
    }

    func promoteToFullCover() {
        presentationPhase = .fullCover
    }

    func demoteToSheet() {
        presentationPhase = .sheetLarge
    }

    func updateDetent(_ detent: SheetDetent) {
        switch detent {
        case .medium: presentationPhase = .sheetMedium
        case .large:  presentationPhase = .sheetLarge
        }
    }
}
