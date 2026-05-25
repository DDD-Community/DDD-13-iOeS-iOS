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
    private let debounceMillis: Int
    private var lastViewport: Viewport?
    private var currentTheme: String?
    private var debounceTask: Task<Void, Never>?

    /// 지도 카메라 이동/초기 진입 시 viewportChanged 가 짧은 간격으로 중복 발사되는 것을
    /// 마지막 호출 1회만 fetch 되도록 디바운스. 테스트에선 0ms 로 즉시 fetch.
    init(clusteringService: ClusteringServiceProtocol, debounceMillis: Int = 300) {
        self.clusteringService = clusteringService
        self.debounceMillis = debounceMillis
    }

    func viewportChanged(_ viewport: Viewport) async {
        debounceTask?.cancel()
        lastViewport = viewport
        let theme = currentTheme
        let task = Task { [weak self, debounceMillis] in
            if debounceMillis > 0 {
                try? await Task.sleep(for: .milliseconds(debounceMillis))
            }
            guard !Task.isCancelled, let self else { return }
            await self.fetch(viewport: viewport, theme: theme)
        }
        debounceTask = task
        await task.value
    }

    func themeChanged(_ theme: String?) async {
        currentTheme = theme
        guard let viewport = lastViewport else { return }
        await fetch(viewport: viewport, theme: theme)
    }

    func spotMarkerTapped(_ spotId: Int64) {
        selectedSpotId = spotId
    }

    /// 지도 빈 공간 탭 시 선택 해제.
    func mapBackgroundTapped() {
        selectedSpotId = nil
    }

    private func fetch(viewport: Viewport, theme: String?) async {
        // 큐레이션 spots와 my spots를 병행 fetch — 한쪽 실패해도 다른쪽은 살림.
        async let curationTask = clusteringService.fetchClusterableSpots(viewport: viewport, theme: theme)
        async let mySpotsTask = (try? clusteringService.fetchMySpots(viewport: viewport)) ?? []

        do {
            let spots = try await curationTask
            state = .loaded(spots: spots)
        } catch {
            state = .failed(error.localizedDescription)
        }
        mySpots = await mySpotsTask
    }
}

extension MapClusteringViewModel.LoadState {
    var spots: [ClusterableSpot] {
        if case .loaded(let spots) = self { return spots }
        return []
    }
}
