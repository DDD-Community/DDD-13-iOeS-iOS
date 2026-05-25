import Foundation

@MainActor
final class SpotDetailViewModel: ObservableObject {
    enum PreviewState: Equatable {
        case idle
        case loading
        case loaded(SpotPreviewResponse)
        case failed(String)
    }

    enum DetailState: Equatable {
        case idle
        case loading
        case loaded(SpotDetail)
        case failed(String)
    }

    @Published private(set) var previewState: PreviewState = .idle
    @Published private(set) var detailState: DetailState = .idle
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

    private var detailLoadTask: Task<Void, Never>?

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
        previewState = .loading

        let coordinate = locationService.lastKnownLocation

        do {
            let preview = try await spotService.fetchSpotPreview(
                id: spotId,
                latitude: coordinate?.latitude,
                longitude: coordinate?.longitude
            )
            previewState = .loaded(preview)
        } catch {
            previewState = .failed(error.localizedDescription)
        }
        // detailState 는 .idle 유지 — sheet large 진입 시 loadDetailIfNeeded() 가 트리거.
    }

    func loadDetailIfNeeded() {
        switch detailState {
        case .loading, .loaded:
            return
        case .idle, .failed:
            break
        }
        if detailLoadTask != nil { return }
        detailState = .loading
        detailLoadTask = Task { [weak self] in
            await self?.performDetailLoad()
        }
    }

    private func performDetailLoad() async {
        defer { detailLoadTask = nil }
        let coordinate = locationService.lastKnownLocation
        do {
            let spot = try await spotService.fetchSpotDetail(
                id: spotId,
                latitude: coordinate?.latitude,
                longitude: coordinate?.longitude
            )
            isBookmarked = spot.isBookmarked
            detailState = .loaded(spot)
        } catch {
            detailState = .failed(error.localizedDescription)
        }
    }

    func toggleBookmark() async {
        guard (try? tokenStore.load()) != nil else {
            isLoginRequired = true
            return
        }

        let previousValue = isBookmarked
        isBookmarked.toggle()

        do {
            if previousValue {
                try await bookmarkService.deleteBookmark(spotId: spotId)
            } else {
                try await bookmarkService.addBookmark(spotId: spotId)
            }
            NotificationCenter.default.post(name: .spotBookmarkDidChange, object: nil)
        } catch BookmarkError.alreadyBookmarked {
            isBookmarked = true
            NotificationCenter.default.post(name: .spotBookmarkDidChange, object: nil)
        } catch {
            isBookmarked = previousValue
            toast = "북마크 변경에 실패했어요."
        }
    }

    func openNaverMapsRoute() {
        guard case let .loaded(spot) = detailState else { return }
        externalAppLauncher.openNaverMapsRoute(latitude: spot.latitude, longitude: spot.longitude, name: spot.name)
    }

    func share() {
        guard case let .loaded(spot) = detailState else { return }

        analyticsLogger.log(SpotDetailAnalyticsEvent.shareButtonTap)

        let text = "\(spot.name) - \(spot.comment)\nhttps://pickflow.app/spot/\(spot.id)"
        let deviceId = deviceIdProvider()
        Task {
            try? await shareIntentService.recordIntent(deviceId: deviceId)
        }
        shareSheetPresenter.present(items: [text])
    }

    func reportInvalidInfo() {
        guard case .loaded = detailState else { return }
        Task {
            do {
                try await spotService.reportSpot(id: spotId, type: .etc, content: "")
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
        loadDetailIfNeeded()
    }

    func demoteToSheet() {
        presentationPhase = .sheetLarge
        loadDetailIfNeeded()
    }

    func updateDetent(_ detent: SheetDetent) {
        switch detent {
        case .medium: presentationPhase = .sheetMedium
        case .large:
            presentationPhase = .sheetLarge
            loadDetailIfNeeded()
        }
    }
}
