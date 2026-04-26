import CoreLocation
import Foundation

// 지도에 표시할 장소 모델 (API 명세 확정 후 필드 보강 예정)
struct MapPlace: Identifiable, Equatable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let mood: MoodFilter?

    static func == (lhs: MapPlace, rhs: MapPlace) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
final class HomeMapViewModel: ObservableObject {
    // 사용자가 선택한 무드 필터 (없으면 전체)
    @Published var selectedMood: MoodFilter?
    // 지도/리스트 토글 상태
    @Published var mapListMode: MapListMode = .map
    // 장소 추가 화면 표시 여부
    @Published var isAddPlacePresented: Bool = false
    // 지도/리스트에 표시할 장소 목록
    @Published private(set) var places: [MapPlace] = []
    // 사용자의 현재 위치 (위치 권한/추적 결과)
    @Published private(set) var currentLocation: CLLocationCoordinate2D?
    // 로딩 상태
    @Published private(set) var isLoading: Bool = false
    // 에러 메시지 (사용자 노출용)
    @Published var errorMessage: String?

    init() {
        // 의존성(서비스) 주입은 API 명세 확정 후 추가 예정
    }

    // 무드 필터 토글 (같은 항목 재선택 시 해제)
    func toggleMood(_ mood: MoodFilter) {
        selectedMood = (selectedMood == mood) ? nil : mood
        Task { await fetchPlaces() }
    }

    // 지도/리스트 모드 변경
    func setMapListMode(_ mode: MapListMode) {
        mapListMode = mode
    }

    // 장소 추가 화면 진입
    func presentAddPlace() {
        isAddPlacePresented = true
    }

    // 현재 위치로 카메라 이동 (실제 이동은 NaverMapView 와 연동 예정)
    func moveToCurrentLocation() async {
        // TODO: 위치 권한 확인 및 CLLocationManager 연동
        // TODO: NaverMapView 카메라 업데이트 트리거
    }

    // 화면 진입 시 초기 데이터 로드
    func onAppear() async {
        await fetchPlaces()
    }

    // 선택된 무드 필터 기준 장소 목록 조회 (API 연동 예정)
    func fetchPlaces() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // TODO: PlaceService.fetchPlaces(mood: selectedMood) 호출로 대체
        // 현재는 스텁 - 빈 배열 유지
        places = []
    }

    // 지도에 표시된 핀(장소) 탭 시 동작 (상세 화면 이동 등)
    func didSelectPlace(_ place: MapPlace) {
        // TODO: 장소 상세 화면 라우팅 연결
    }
}
