import Foundation

/// 탐색 화면 지역 필터(대전/서울)의 앱 전역 선택 상태.
///
/// 앱 부팅 시(ForceUpdate 버전 정책 확인 직후) `loadIfNeeded()`가 먼저 호출되어 활성 지역 목록을
/// 선점 로드한다. 지도/리스트 뷰모델은 각자 fetch 직전에 같은 메서드를 호출해 이미 진행 중인
/// 로드를 기다리기만 하면 되므로, "지역 응답 이후 viewport 호출" 순서가 별도 배선 없이 보장된다.
@MainActor
final class RegionSelectionStore: ObservableObject {
    @Published private(set) var regions: [Region] = []
    @Published private(set) var selectedRegion: Region?

    private let regionService: RegionServiceProtocol
    private let defaults: UserDefaults
    private var loadTask: Task<Void, Never>?

    private static let selectedRegionIdKey = "regionSelection.selectedRegionId"

    init(regionService: RegionServiceProtocol, defaults: UserDefaults = .standard) {
        self.regionService = regionService
        self.defaults = defaults
    }

    func loadIfNeeded() async {
        if let loadTask {
            await loadTask.value
            return
        }
        let task = Task { await performLoad() }
        loadTask = task
        await task.value
    }

    /// 바텀시트 [적용하기] 확정 시 호출. 다음 실행에도 유지되도록 로컬에 저장한다.
    func select(_ region: Region) {
        selectedRegion = region
        defaults.set(region.id, forKey: Self.selectedRegionIdKey)
    }

    private func performLoad() async {
        let fetched = (try? await regionService.fetchActiveRegions()) ?? []
        let loaded = fetched.isEmpty ? Region.fallbackRegions : fetched
        regions = loaded

        let savedId = defaults.object(forKey: Self.selectedRegionIdKey) as? Int
        selectedRegion = loaded.first(where: { $0.id == savedId }) ?? loaded.first
    }
}

@MainActor
func getRegionSelectionStore() -> RegionSelectionStore {
    guard let store = DIContainerHolder.shared?.resolve(RegionSelectionStore.self) else {
        fatalError("RegionSelectionStore is not registered in DIContainer")
    }
    return store
}
