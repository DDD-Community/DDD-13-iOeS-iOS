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
    private var lastViewport: Viewport?
    private var currentTheme: String?

    init(clusteringService: ClusteringServiceProtocol) {
        self.clusteringService = clusteringService
    }

    func viewportChanged(_ viewport: Viewport) async {
        lastViewport = viewport
        await fetch(viewport: viewport, theme: currentTheme)
    }

    func themeChanged(_ theme: String?) async {
        currentTheme = theme
        guard let viewport = lastViewport else { return }
        await fetch(viewport: viewport, theme: theme)
    }

    func spotMarkerTapped(_ spotId: Int64) async {
        selectedSpotId = spotId
    }

    /// 지도 빈 공간 탭 시 선택 해제.
    func mapBackgroundTapped() async {
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
