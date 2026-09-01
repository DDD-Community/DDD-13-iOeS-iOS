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

    // MARK: - PV-40 유저 스팟 공개 시스템

    /// 유저 등록 스팟의 공개 상태. 큐레이션 스팟이면 nil.
    @Published private(set) var publicationStatus: MySpotStatus?
    @Published private(set) var likeCount = 0
    @Published private(set) var isLiked = false
    /// 추천 버튼 노출 여부. 비공개 상태의 유저 스팟에는 버튼 자체가 없다.
    @Published private(set) var canLike = false
    @Published var activeSheet: SpotPublicationSheet?
    @Published private(set) var isOpenCompletePresented = false
    /// 타 유저가 등록한 스팟인지. 큐레이션이거나 판단할 수 없으면 false.
    private var isUserRegisteredSpot = false

    private let spotId: Int64
    private let spotService: SpotServiceProtocol
    private let mySpotService: MySpotServiceProtocol
    private let bookmarkService: BookmarkServiceProtocol
    private let locationService: LocationServiceProtocol
    private let externalAppLauncher: ExternalAppLauncherProtocol
    private let shareSheetPresenter: ShareSheetPresenterProtocol
    private let analyticsLogger: AnalyticsLoggerProtocol
    private let tokenStore: TokenStoreProtocol
    private let deviceIdProvider: @MainActor @Sendable () -> String
    private let clock: @Sendable () -> Date

    private let openCompleteStore: OpenCompleteAcknowledging

    private var detailLoadTask: Task<Void, Never>?
    private var isLikeInFlight = false
    private var isPublicationActionInFlight = false

    init(
        spotId: Int64,
        spotService: SpotServiceProtocol,
        mySpotService: MySpotServiceProtocol = getMySpotService(),
        bookmarkService: BookmarkServiceProtocol,
        locationService: LocationServiceProtocol,
        externalAppLauncher: ExternalAppLauncherProtocol,
        shareSheetPresenter: ShareSheetPresenterProtocol,
        analyticsLogger: AnalyticsLoggerProtocol = getAnalyticsLogger(),
        tokenStore: TokenStoreProtocol = getTokenStore(),
        deviceIdProvider: @escaping @MainActor @Sendable () -> String,
        clock: @escaping @Sendable () -> Date = Date.init,
        openCompleteStore: OpenCompleteAcknowledging = UserDefaultsOpenCompleteStore()
    ) {
        self.spotId = spotId
        self.spotService = spotService
        self.mySpotService = mySpotService
        self.bookmarkService = bookmarkService
        self.locationService = locationService
        self.externalAppLauncher = externalAppLauncher
        self.shareSheetPresenter = shareSheetPresenter
        self.analyticsLogger = analyticsLogger
        self.tokenStore = tokenStore
        self.deviceIdProvider = deviceIdProvider
        self.clock = clock
        self.openCompleteStore = openCompleteStore
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
            isBookmarked = preview.isBookmarked
        } catch let e as APIError {
            previewState = .failed(e.message)
            e.post()
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
            applyPublicationState(from: spot)
            detailState = .loaded(spot)
        } catch let e as APIError {
            detailState = .failed(e.message)
            e.post()
        } catch {
            detailState = .failed(error.localizedDescription)
        }
    }

    /// 로그인(회원) 여부. 회원 전용 기능 진입 전 게이팅에 사용한다.
    var isLoggedIn: Bool {
        (try? tokenStore.load()) != nil
    }

    func toggleBookmark() async {
        guard isLoggedIn else {
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
                // 유저가 등록한 스팟은 작성자가 언제든 되돌릴 수 있다. 저장해 둔 뒤
                // 사라진 것처럼 보이지 않도록 저장하는 시점에 미리 알린다(기획 3.9).
                if isUserRegisteredSpot {
                    showToast("작성자가 언제든 비공개로 전환할 수 있어요")
                }
            }
            NotificationCenter.default.post(
                name: .spotBookmarkDidChange,
                object: SpotBookmarkChange(spotId: spotId, isBookmarked: isBookmarked)
            )
        } catch BookmarkError.alreadyBookmarked {
            isBookmarked = true
            NotificationCenter.default.post(
                name: .spotBookmarkDidChange,
                object: SpotBookmarkChange(spotId: spotId, isBookmarked: true)
            )
        } catch let e as APIError {
            isBookmarked = previousValue
            e.post()
        } catch {
            isBookmarked = previousValue
            toast = "북마크 변경에 실패했어요."
        }
    }

    func openNaverMapsRoute() {
        // medium 시트(SpotDetailSheetContentView)에서는 detailState 가 .idle 이라
        // 기존 guard 에 막혀 silent fail 되던 문제를 해소: 필요하면 detail 을 먼저 로드한 뒤 실행.
        Task { await openNaverMapsRouteFlow() }
    }

    private func openNaverMapsRouteFlow() async {
        if case let .loaded(spot) = detailState {
            externalAppLauncher.openNaverMapsRoute(latitude: spot.latitude, longitude: spot.longitude, name: spot.name)
            return
        }
        loadDetailIfNeeded()
        await detailLoadTask?.value
        if case let .loaded(spot) = detailState {
            externalAppLauncher.openNaverMapsRoute(latitude: spot.latitude, longitude: spot.longitude, name: spot.name)
        }
    }

    func share() {
        Task { await shareFlow() }
    }

    private func shareFlow() async {
        loadDetailIfNeeded()
        await detailLoadTask?.value

        analyticsLogger.log(SpotDetailAnalyticsEvent.shareButtonTap)

        let url = "https://pickflow-api.us/\(SpotIDCoder.encodeSpot(spotId))"
        if case let .loaded(spot) = detailState {
            // 코멘트가 없으면 " - " 만 덩그러니 남지 않도록 스팟명만 공유한다.
            let title = [spot.name, spot.comment].compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " - ")
            shareSheetPresenter.present(items: ["\(title)\n\(url)"])
        } else {
            shareSheetPresenter.present(items: [url])
        }
    }
    
    func reportInvalidInfo(content: String) {
        guard case .loaded = detailState else { return }
        Task {
            do {
                try await spotService.reportSpot(id: spotId, content: content)
                showToast("제보가 접수되었습니다.")
            } catch let e as APIError {
                e.post()
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


    // MARK: - PV-40 유저 스팟 공개 시스템

    private func applyPublicationState(from spot: SpotDetail) {
        publicationStatus = spot.status
        likeCount = spot.likeCount ?? 0
        isLiked = spot.isLiked ?? false
        canLike = spot.isLikeable ?? (spot.isCurated ?? false)
        isUserRegisteredSpot = !spot.isMySpot && spot.isCurated == false

        let isApprovedMySpot = spot.isMySpot && spot.status == .published
        if isApprovedMySpot, !openCompleteStore.hasAcknowledged(spotId: spotId) {
            isOpenCompletePresented = true
        }
    }

    // MARK: 추천

    func toggleLike() async {
        guard isLoggedIn else {
            isLoginRequired = true
            return
        }
        // 연타로 요청이 겹치면 서버 카운트와 화면이 어긋난다.
        guard !isLikeInFlight else { return }
        isLikeInFlight = true
        defer { isLikeInFlight = false }

        let previousIsLiked = isLiked
        let previousCount = likeCount
        updateLikeState(count: max(0, previousCount + (previousIsLiked ? -1 : 1)), isLiked: !previousIsLiked)

        do {
            let response = previousIsLiked
                ? try await spotService.unlikeSpot(id: spotId)
                : try await spotService.likeSpot(id: spotId)
            // 서버에 최종 반영된 값이 진실이다.
            updateLikeState(count: response.likeCount, isLiked: response.isLiked)
        } catch {
            updateLikeState(count: previousCount, isLiked: previousIsLiked)
            showToast(error.spotPublicationErrorCode?.userMessage ?? "잠시 후 다시 시도해주세요.")
        }
    }

    /// `likeCount`/`isLiked` 는 헤더 등 여러 컴포넌트가 `detailState` 에 담긴
    /// `SpotDetail` 을 직접 읽으므로, 별도 published 프로퍼티만 갱신하면
    /// 화면에 반영되지 않는다(publicationStatus 와 같은 이유).
    private func updateLikeState(count: Int, isLiked: Bool) {
        likeCount = count
        self.isLiked = isLiked

        NotificationCenter.default.post(
            name: .spotLikeDidChange,
            object: SpotLikeChange(spotId: spotId, likeCount: count, isLiked: isLiked)
        )

        guard case var .loaded(spot) = detailState else { return }
        spot.likeCount = count
        spot.isLiked = isLiked
        detailState = .loaded(spot)
    }

    // MARK: 시트

    func presentSheet(_ sheet: SpotPublicationSheet) {
        activeSheet = sheet
    }

    func dismissSheet() {
        activeSheet = nil
    }

    func acknowledgeOpenComplete() {
        isOpenCompletePresented = false
        openCompleteStore.acknowledge(spotId: spotId)
    }

    // MARK: 오픈 신청 / 공개 해제 / 삭제

    func confirmOpenRequest() async {
        guard !isPublicationActionInFlight else { return }
        isPublicationActionInFlight = true
        defer { isPublicationActionInFlight = false }

        activeSheet = nil
        do {
            let response = try await mySpotService.requestOpen(spotId: spotId)
            updatePublicationStatus(response.status)
            showToast("오픈 신청이 접수되었어요.")
        } catch {
            await handlePublicationFailure(error)
        }
    }

    func confirmCancelPublication() async {
        guard !isPublicationActionInFlight else { return }
        isPublicationActionInFlight = true
        defer { isPublicationActionInFlight = false }

        activeSheet = nil
        do {
            let response = try await mySpotService.cancelPublication(spotId: spotId)
            updatePublicationStatus(response.status)
        } catch {
            await handlePublicationFailure(error)
        }
    }

    private func updatePublicationStatus(_ status: MySpotStatus?) {
        publicationStatus = status

        guard case var .loaded(spot) = detailState else { return }
        spot.status = status
        if status != .rejected {
            spot.rejection = nil
        }
        if status != .published {
            spot.isLikeable = false
            canLike = false
        }
        detailState = .loaded(spot)
    }

    func confirmDelete() async {
        guard !isPublicationActionInFlight else { return }
        isPublicationActionInFlight = true
        defer { isPublicationActionInFlight = false }

        activeSheet = nil
        do {
            try await mySpotService.deleteMySpot(spotId: spotId)
            NotificationCenter.default.post(name: .spotBookmarkDidChange, object: nil)
            dismissRequested = true
        } catch {
            await handlePublicationFailure(error)
        }
    }

    /// 오픈 신청/철회/삭제 실패 처리.
    /// 검수 결과가 이미 확정된 경합(SP004)이면 최신 상태로 화면을 다시 맞춘다.
    private func handlePublicationFailure(_ error: any Error) async {
        guard let code = error.spotPublicationErrorCode else {
            showToast("실패했어요, 다시 시도해주세요.")
            return
        }
        showToast(code.userMessage)
        if code == .alreadyReviewed {
            await reloadDetail()
        }
    }

    /// 재신청 폼을 닫은 뒤 최신 상태(검수중)로 화면을 맞춘다.
    func refreshAfterResubmission() async {
        await reloadDetail()
    }

    /// 재신청 제출이 성공했을 때만 부른다. 시안이 신규 등록과 같은 문구를 쓰라고
    /// 명시했다("[등록] 선택 시 기존 등록 플로우와 동일, success toast").
    func showResubmissionSuccessToast() {
        showToast("나만의 스팟이 등록되었어요!")
    }

    /// 서버 상태가 바뀐 게 확실할 때 상세를 강제로 다시 읽는다.
    private func reloadDetail() async {
        detailLoadTask?.cancel()
        detailLoadTask = nil
        detailState = .loading
        await performDetailLoad()
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
