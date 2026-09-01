import Foundation

@MainActor
final class MapClusteringViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(spots: [ClusterableSpot])
        case failed(String)
    }

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var mySpots: [MySpot] = []
    @Published private(set) var selectedSpotId: Int64?

    private let clusteringService: ClusteringServiceProtocol
    private let regionSelectionStore: RegionSelectionStore
    private let debounceMillis: Int
    private var lastViewport: Viewport?
    private var currentThemes: Set<SpotTheme> = []
    private var debounceTask: Task<Void, Never>?

    /// 지도 카메라 이동/초기 진입 시 viewportChanged 가 짧은 간격으로 중복 발사되는 것을
    /// 마지막 호출 1회만 fetch 되도록 디바운스. 테스트에선 0ms 로 즉시 fetch.
    init(
        clusteringService: ClusteringServiceProtocol,
        regionSelectionStore: RegionSelectionStore,
        debounceMillis: Int = 300
    ) {
        self.clusteringService = clusteringService
        self.regionSelectionStore = regionSelectionStore
        self.debounceMillis = debounceMillis
    }

    func viewportChanged(_ viewport: Viewport) async {
        debounceTask?.cancel()
        lastViewport = viewport
        let themes = currentThemes
        let task = Task { [weak self, debounceMillis] in
            if debounceMillis > 0 {
                try? await Task.sleep(for: .milliseconds(debounceMillis))
            }
            guard !Task.isCancelled, let self else { return }
            await self.fetch(viewport: viewport, themes: themes)
        }
        debounceTask = task
        await task.value
    }

    func themeChanged(_ themes: Set<SpotTheme>) async {
        currentThemes = themes
        guard let viewport = lastViewport else { return }
        await fetch(viewport: viewport, themes: themes)
    }

    func spotMarkerTapped(_ spotId: Int64) {
        selectedSpotId = spotId
    }

    /// 지도 빈 공간 탭 시 선택 해제.
    func mapBackgroundTapped() {
        selectedSpotId = nil
    }

    private func fetch(viewport: Viewport, themes: Set<SpotTheme>) async {
        // 스플래시 단계에서 선점 로드가 시작되므로 대부분 즉시 반환되고, 드물게 아직 진행 중이면 여기서 기다린다.
        await regionSelectionStore.loadIfNeeded()
        let regionId = regionSelectionStore.selectedRegion?.id

        // viewport 1회 호출로 curation/mySpots 동시 수신 — 동일 엔드포인트를 2번 때리는 문제 제거.
        do {
            let (curation, mine) = try await clusteringService.fetchSpots(
                viewport: viewport,
                themes: themes,
                regionId: regionId
            )
            state = .loaded(spots: curation)
            mySpots = mine
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

extension MapClusteringViewModel.LoadState {
    var spots: [ClusterableSpot] {
        if case .loaded(let spots) = self { return spots }
        return []
    }
}
