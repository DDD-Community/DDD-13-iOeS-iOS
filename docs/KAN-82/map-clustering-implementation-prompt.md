# [KAN-82] 지도 클러스터링 화면 구현 통합 프롬프트

> **이 프롬프트의 사용법**: `screen-tdd-prompt` 스킬이 [prompt-template.md](../../.claude/skills/screen-tdd-prompt/prompt-template.md)를 복제·치환한 결과물. 이후 Claude는 이 한 장(+ 단계 진입 시 리프 문서)만으로 화면을 구현한다.
>
> **방법론은 여기 없다.** TDD 단계별 디테일은 단계 진입 시 리프 문서를 읽는다:
> - Phase A: [docs/phases/phase-a-viewmodel-tdd.md](../phases/phase-a-viewmodel-tdd.md)
> - Phase B: [docs/phases/phase-b-ui-cases.md](../phases/phase-b-ui-cases.md)
> - Phase C: [docs/phases/phase-c-snapshot.md](../phases/phase-c-snapshot.md)
>
> 본 문서는 **이 화면에만 해당하는 사실**(스코프, API, 정책, 에셋, 컴포넌트 매핑)을 담는다.

---

## 0. 작업 컨텍스트 (선결 정보)

**브랜치**: `feature/KAN-82` (이미 develop에서 분기/체크아웃됨)
**티켓**: https://dddios1.atlassian.net/browse/KAN-82
**전체 화면 Figma**: https://www.figma.com/design/LyduUVMjsQi0qyUsENriR5/DDD-design?node-id=908-18395
- File key: `LyduUVMjsQi0qyUsENriR5`
- Root node-id: `908:18395`

**프로젝트 가정 (재탐색 불필요)**:
- SwiftUI + MVVM, Tuist 매니페스트(`Project.swift`)
- 외부 의존성: Alamofire, Swinject, KakaoSDK*, **nMapsMap (NMFMapView 인앱 사용)**, FirebaseMessaging
- DI: `AppContainer.shared.registerDependencies()` → `getXxxService()` MainActor 헬퍼 / **이번 화면은 protocol 기반 다형성으로 ViewModel·Service 분리 (정책 4)**
- 디자인 시스템: `Resources/DesignSystem/Colors.xcassets` → `UIAsset.Colors.*` 자동 생성, `Common/DesignSystem/Fonts/PickflowTypography.swift`의 `.pretendard(...)` 토큰
- 테스트 타겟 `PickflowTests` 존재 (KAN-51부터). 신규 테스트는 거기에 추가
- `SWIFT_STRICT_CONCURRENCY: complete` — 모든 신규 타입 `Sendable`/`@MainActor` 명시
- 선례: KAN-51(`Feature/SpotDetail/*`), KAN-46/55 (Map 기존 코드 — `Feature/Map/HomeMapView*`, `NaverMapView`)
- **클러스터링 패러다임 (중요)**: 클러스터링 **알고리즘은 클라이언트** `NMCClusterer`가 수행. 서버는 **viewport 영역 안의 스팟 raw 리스트를 `NMCClusterer`가 받아들일 수 있는 양식으로 내려줌** — viewport 전달은 "묶어달라"가 아니라 "이 영역의 스팟만 보내달라"는 필터. 줌 레벨에 따른 클러스터/리프 분기는 `NMCClusterer`의 기본 동작에 위임.

- **기존 Map 자산 처리 결정 (2026-05-08 확정)**:
  - `Feature/Map/HomeMapViewModel.swift` — **chrome 책임 그대로 유지** (무드 필터, 리스트 토글, 장소 추가, 현재 위치). 클러스터링 책임은 절대 여기 추가하지 않음
  - `Feature/Map/HomeMapView.swift` — 현재 `@State`만 쓰는 상태. KAN-82에서 `HomeMapViewModel` + 신규 `MapClusteringViewModel` **두 VM을 모두 주입**받는 형태로 변경
  - `Feature/Map/NaverMapView.swift` — **수정 (대체 아님)**: `NMCClusterer` 운용 코드는 **유지**하되, 입력을 dummy data 대신 ViewModel이 publish하는 `[ClusterableSpot]`로 교체. `LeafMarkerUpdater`/`ClusterMarkerUpdater`는 §8.1 디자인(`sunsetOrange` + 검정 그라데이션 + `Maps/icPhoto`)에 맞춰 재구현. viewport idle / 마커 탭 콜백을 상위로 노출
  - `Feature/Map/ClusteringExampleView.swift` — **삭제 (2026-05-11)**. NMC SDK 통합 학습용 PoC였고 본 PR에서 검증 통제군으로 사용 후 정리
  - `Core/Services/MapService.swift` + `MapServiceProtocol.swift` — KAN-82 신규 `ClusteringServiceProtocol` / `SpotsServiceProtocol`과 **책임 분리**. 기존 `MapService`는 건드리지 않고 신규 protocol 별도 파일로 추가

---

## 1. 스코프

**구현 범위**:
- 지도 화면에서 **viewport 4 귀퉁이 좌표를 서버에 전달** → viewport 영역의 **스팟 raw 리스트**(`[ClusterableSpot]`) 응답 받기
- 응답을 `NMCClusterer`에 주입 → **클라이언트 사이드 클러스터링 수행** → 클러스터 마커 / 리프 마커 렌더링
- 큐레이션 스팟이 클러스터링 대상 (개수 표기된 클러스터 핀 + 단일 리프 마커)
- 카메라 이동/줌 변경 → debounce 후 재요청
- 줌 임계값 이상 / 클러스터 탭 → 자연스럽게 리프 마커로 전환 (NMCClusterer 기본 동작 활용)
- 리프 마커 탭 → 해당 spot id로 `GET /spots/{id}` 로드 (상세는 KAN-51 SpotDetail 위임)
- 의존성 주입은 **protocol 기반 다형성** — `ClusteringServiceProtocol`, `SpotsServiceProtocol`로 ViewModel과 분리

**범위 밖** (이번 티켓에서 의도적으로 제외):
- my spot (직접 등록한 스팟) 마커 렌더링은 **별도 커스텀 마커로 표시하되, 본 티켓의 클러스터링 응답·핀 처리에는 포함하지 않음**. my spot 데이터 소스 통합은 후속 티켓
- 테마 필터 UI (API 파라미터 `theme`은 받되, 이번 화면에서 변경 UI는 다루지 않음 — 상위 화면에서 주입받는 형태)
- 스팟 상세 화면 자체 (KAN-51에서 구현 완료, 본 티켓은 진입점 연결만)
- 비로그인 처리 / 일몰 표시 / 거리 표시 등 KAN-51 정책

---

## 2. 핵심 정책 결정 (사용자 확정)

| # | 항목 | 결정 |
|---|---|---|
| 1 | 클러스터링 데이터 소스 | **큐레이션 스팟만** 클러스터링에 참여 |
| 2 | my spot 처리 | 클러스터링에 참여하지 않음. 별도 커스텀 마커로 (본 티켓 범위 밖, 인터페이스만 분리해 충돌 방지) |
| 3 | viewport 전달 방식 | **화면 4귀퉁이 좌표(좌상/우상/좌하/우하)** 를 서버에 전달 |
| 4 | 의존성 주입 | `protocol`로 다형성 보장 — ViewModel은 `*ServiceProtocol`에만 의존, 테스트는 Mock으로 대체 |
| 5 | 서버 미동작 시 | **스텁 구현으로 진행** — Mock 서비스 또는 in-memory fixture로 Phase A·B·C 모두 가능하도록 |
| 6 | 화면 이름 (자연어) | "지도 클러스터링" 가칭. <!-- TODO: Jira 티켓 본문 또는 디자인 영역명 확정 후 갱신 --> |

---

## 3. API 매핑 (스텁 단계)

> 서버는 아직 동작 안 함. 형태가 변할 수 있다는 전제 하에 **인터페이스를 protocol로 격리**하고, Phase A에서는 in-memory fixture 응답을 쓰는 Mock 구현을 사용한다.
>
> **명명 주의**: 엔드포인트 이름이 `/clustering`이지만 응답은 "묶인 클러스터"가 아니라 "viewport 안의 스팟 raw 리스트"다. 클러스터링은 클라이언트가 한다.

| UI 동작 | Endpoint | 응답 형태 | 비고 |
|---|---|---|---|
| 카메라 이동/줌 변경 (debounce 후) | `GET /clustering` (query: viewport 4 corners) | `[ClusterableSpot]` (좌표 + spot id + 메타) | 서버는 viewport 영역 필터만 수행, 클러스터링은 `NMCClusterer`. viewport 직렬화 형식은 <!-- TODO: 서버와 합의 — `bbox=lat1,lng1,lat2,lng2` vs 4개 좌표 분리 --> |
| 화면 진입 시 초기 큐레이션 스팟 (선택) | `GET /spots` (query: `latitude`, `longitude`, `theme`) | `[Spot]` (목록) | 사용 여부는 §1 스코프 합의에 따라. `/clustering` 단독으로 충분하면 사용 안 함 |
| 단일 리프 마커 탭 → 상세 진입 | `GET /spots/{id}` (query optional: `latitude`, `longitude`) | `SpotDetail` | 응답 모델은 KAN-51 `SpotDetail` 재사용 가능 여부 확인 |

JSONDecoder는 `convertFromSnakeCase` 전역 적용 → 모델엔 CodingKeys 박지 않는다.

---

## 4. 신규/수정 파일 목록

> 기존 `Core/Services` 컨벤션(Endpoints / Models / Protocols / `XxxService.swift`)을 그대로 따른다. Mock은 `PickflowTests/Helpers/<Feature>TestDoubles.swift` 단일 파일.

**신규**
```
Pickflow/Sources/Core/Services/
├── Endpoints/
│   └── ClusteringEndpoint.swift          # struct + APIEndpoint, GET /clustering (viewport, theme?)
│                                         #   (SpotEndpoint.swift 는 기존 재사용 — id/lat/lng)
├── Models/
│   ├── Viewport.swift                    # 4 corners (Codable, Sendable, Equatable)
│   └── ClusterableSpot.swift             # 서버 응답 1행: id + Coordinate + 메타 (NMCClusterer 입력 양식)
│                                         #   (Coordinate.swift 는 기존 재사용 ⭐)
├── Protocols/
│   └── ClusteringServiceProtocol.swift   # protocol + getClusteringService() @MainActor 헬퍼 (한 파일)
│                                         #   (SpotServiceProtocol.swift 는 기존 확장 — 메서드 추가)
└── ClusteringService.swift               # final class, NetworkManagerProtocol 주입
                                          #   서버 미동작 → fatalError("Not implemented") 또는 fixture sleep 스텁

Pickflow/Sources/Feature/Map/Clustering/
├── MapClusteringViewModel.swift          # @MainActor, ObservableObject (raw [ClusterableSpot] 보유)
└── MapSpotClusterKey.swift               # NMCClusteringKey 구현 (ClusterableSpot ↔ NMGLatLng)

PickflowTests/
├── Helpers/
│   └── MapClusteringTestDoubles.swift    # MockClusteringService 신규 + ClusterableSpot.fixture
│                                         #   (MockSpotService는 SpotDetailTestDoubles.swift 재사용)
└── MapClusteringViewModelTests.swift     # Phase A 테스트
```

> `Cluster` 모델은 만들지 않는다 — 클러스터는 `NMCClusterer`가 런타임에 만드는 일시적 결과물(`NMCClusterMarkerInfo`)일 뿐 ViewModel 상태에 들어갈 게 아니다.

**수정**
- `Pickflow/Sources/Core/Services/Protocols/SpotServiceProtocol.swift` — 기존 `fetchSpotDetail` 그대로 두고, **viewport/theme 기반 spots 목록 메서드 추가** 여부 결정:
  - 안 1: `SpotServiceProtocol`에 `fetchSpots(latitude:longitude:theme:)` 추가
  - 안 2: `ClusteringServiceProtocol`에 통합 (viewport-based 모두 한 곳)
  - **권장: 안 2** — KAN-82 스코프(클러스터링 핀 응답)에 맞춰 `ClusteringService`가 viewport 호출 전담. `SpotServiceProtocol`은 단일 spot 상세만
- `Pickflow/Sources/Core/Services/SpotService.swift` — 위 결정에 따라 메서드 추가 (안 2면 수정 0)
- `Pickflow/Sources/App/AppContainer.swift` — 기존 컨벤션 그대로 한 줄 추가:
  ```swift
  container.register(ClusteringServiceProtocol.self) { ClusteringService(networkManager: networkManager) }
  ```
- `Pickflow/Sources/Feature/Map/HomeMapView.swift` — `MapClusteringViewModel` 추가 주입 + 무드/viewport 라우팅
- `Pickflow/Sources/Feature/Map/HomeMapViewModel.swift` — chrome 책임만 유지 (변경 없음. 본 티켓에서 `HomeMapView`에 처음 연결됨)
- `Pickflow/Sources/Feature/Map/NaverMapView.swift` — **수정 (대체 아님)**:
  - `NMCClusterer` 운용 코드는 **유지**, dummy data(`MapPlace.dummies` / `ExampleItemKey` 직주입)만 제거
  - 입력을 `spots: [ClusterableSpot]`로 교체 → Coordinator가 `NMCClusterer.clear()` + `addAll(MapSpotClusterKey 변환)` 동기화
  - viewport idle 콜백 → `onViewportChange: (Viewport) -> Void`로 상위 노출. **debounce는 여기서 적용** (Combine `.debounce(for:scheduler:)` 또는 NMFMapView idle 콜백 자체의 throttle 활용 — ViewModel 진입 전에 처리)
  - 리프 마커 탭 콜백 → `onSpotTap: (_ spotId: String) -> Void`. 클러스터 마커 탭은 NMCClusterer 기본 동작(줌인)에 위임
  - `LeafMarkerUpdater` / `ClusterMarkerUpdater` → §8.1 디자인으로 갱신 (sunsetOrange / 검정 그라데이션 top→bottom / icPhoto / 선택 시 4px border)

**보류 (이번 PR에서 손대지 않음)**
- `Pickflow/Sources/Feature/Map/ClusteringExampleView.swift` — **삭제** (학습 통제군 역할 종료)

> Tuist 매니페스트가 폴더 변경을 자동 감지한다. 신규 파일 추가 후 빌드/테스트 실행 시 자동 반영됨.

---

### 4.1 기존 컨벤션 요약 (재확인)

| 영역 | 패턴 | KAN-82 적용 |
|---|---|---|
| Endpoint | `struct XxxEndpoint: APIEndpoint`, `baseURL`/`path`/`method`/`parameters` 4 멤버 | `ClusteringEndpoint(viewport: Viewport, theme: String?)` |
| Model | `Codable, Sendable, Equatable` (+ `Identifiable` 선택). CodingKeys 박지 않음 — 전역 `convertFromSnakeCase` | `Viewport`, `ClusterableSpot` |
| Protocol | `protocol XxxServiceProtocol: Sendable` + 같은 파일에 `@MainActor func getXxxService() -> XxxServiceProtocol` 헬퍼 | `ClusteringServiceProtocol` + `getClusteringService()` |
| Service 구현 | `final class XxxService: XxxServiceProtocol, Sendable`, `NetworkManagerProtocol` 생성자 주입 | `ClusteringService` |
| 미구현 stub | `fatalError("Not implemented")` (즉시 크래시 안전) 또는 `Task.sleep + fixture` (화면 흐름 진행) | `ClusteringService.fetchClusterableSpots`는 **fixture 반환 스텁** 권장 — 디버그 진입점에서 클러스터 핀 표시되도록 |
| Mock | `final class MockXxxService: XxxServiceProtocol, @unchecked Sendable`, `var result: Result<...>` + `private(set) var requests` 캡처. 위치 = `PickflowTests/Helpers/<Feature>TestDoubles.swift` | `MockClusteringService` (신규) + `MockSpotService` 재사용 |
| Fixture | `extension XxxModel { static func fixture(...) -> XxxModel }` — TestDoubles 파일 안 | `ClusterableSpot.fixture(id:coordinate:)` |
| AppContainer 등록 | `container.register(XxxServiceProtocol.self) { XxxService(networkManager: networkManager) }` 한 줄 | 동일 |

<!-- 위 신규 블록에 통합 정리되었음 -->

---

## 5. 모델 정의 가이드

```swift
// Sendable, Codable. CodingKeys는 박지 않음 (convertFromSnakeCase 전역).
// Coordinate는 기존 Core/Services/Models/Coordinate.swift 재사용 (Codable, Sendable, Hashable).

struct Viewport: Codable, Sendable, Equatable {
    let topLeft: Coordinate
    let topRight: Coordinate
    let bottomLeft: Coordinate
    let bottomRight: Coordinate
}

// 서버 응답 1행. NMCClusterer가 받아들일 수 있는 양식(좌표 + 식별자).
struct ClusterableSpot: Codable, Sendable, Identifiable, Equatable {
    let id: Int64               // spot id (기존 SpotDetail.id 가 Int64 — 일관성)
    let coordinate: Coordinate
    // TODO: 서버 합의 후 추가 — 카테고리(theme), 썸네일 url 등 리프 마커 표현 메타
}
```

```swift
// NMCClusteringKey 구현 — ClusterableSpot ↔ NMGLatLng 어댑터.
// Feature/Map/Clustering/MapSpotClusterKey.swift.
final class MapSpotClusterKey: NSObject, NMCClusteringKey {
    let spotId: Int64
    let position: NMGLatLng
    init(spot: ClusterableSpot) {
        self.spotId = spot.id
        self.position = NMGLatLng(lat: spot.coordinate.latitude, lng: spot.coordinate.longitude)
    }
    // hash / isEqual / copy(with:) — 기존 NaverMapView.MapPlaceClusterKey 패턴 참고
}
```

> **`Cluster` 모델은 정의하지 않는다.** "클러스터"는 `NMCClusterer`가 런타임에 만드는 결과물(`NMCClusterMarkerInfo`)일 뿐, ViewModel 상태에 들어갈 도메인 객체가 아니다. ViewModel은 raw `[ClusterableSpot]`만 보유하고, 묶기/풀기/줌 임계 분기는 `NMCClusterer`의 기본 동작에 위임한다.
>
> 현재 모델은 **Phase A 작업용 가설**이다. 서버 합의 후 필드 추가가 있어도 `ClusteringServiceProtocol` 시그니처는 그대로 유지하고 실서버 구현·모델 매핑만 손본다. ViewModel은 protocol에만 의존하므로 영향 격리됨.

---

## 6. ViewModel 시그니처 — 두 VM 병행 (KAN-82 정책)

> `HomeMapView`가 두 VM을 동시에 주입받는다. 책임이 겹치지 않도록 명확히 분리.
>
> **의존성 원칙 (코드베이스 표준)**:
> - ViewModel의 저장 프로퍼티 타입은 **반드시 protocol** (`any ClusteringServiceProtocol` / `any SpotServiceProtocol`). 구현체(`ClusteringService`, `SpotService`) 직접 참조 금지
> - View는 ViewModel(ObservableObject)에만 의존, Service에 직접 접근 금지
> - 서비스는 `getXxxService() @MainActor` 헬퍼로 resolve하여 ViewModel 생성 시 주입
> - 테스트는 `MockXxxService` 주입으로 100% 통과 — 실서비스 의존 0

### 6.1 `MapClusteringViewModel` (신규 — 본 티켓 핵심)

```swift
@MainActor
final class MapClusteringViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(spots: [ClusterableSpot])   // raw — 클러스터링은 NMCClusterer가 수행
        case failed(String)
    }

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var selectedSpotId: String?

    init(
        clusteringService: ClusteringServiceProtocol       // 단일 의존성 — Phase A 진입 시 spotService 제거 결정 (안 2)
    )

    func viewportChanged(_ viewport: Viewport) async       // 즉시 fetch — debounce는 NaverMapView 측 카메라 idle 콜백에서 처리 (Phase A 안티 패턴 회피)
    func spotMarkerTapped(_ spotId: Int64) async           // selectedSpotId만 set → 상위 화면이 navigate
    func themeChanged(_ theme: String?) async              // mood 필터 변경 시 HomeMapView가 호출 → 마지막 viewport로 재fetch
}
```

> **클러스터 마커 탭 / 줌 임계에 따른 분기**는 `NMCClusterer`의 기본 동작(또는 `NMCBuilder.minClusteringZoom` 등 옵션)으로 처리한다. ViewModel이 알 필요 없음 → `isClusteringDisabled`, `clusterTapped`, `zoomDisableThreshold` 모두 ViewModel에서 제거.
>
> 단, NMCClusterer 옵션 튜닝(예: `minClusteringZoom` 임계값)은 `NaverMapView` 안에서 결정 — Phase A 시점엔 기본값으로 두고 Phase C 시각 검증 시 조정.
>
> **단일 spot 상세 진입은 ViewModel 책임 아님**: `spotMarkerTapped(_ spotId:)`는 `selectedSpotId`만 publish. 상세 fetch는 KAN-51 `SpotDetailViewModel`이 자체 수행. 따라서 본 ViewModel은 `SpotServiceProtocol`을 의존하지 않는다.

### 6.2 `HomeMapViewModel` (기존 — 본 티켓에서 책임 변경 없음)

- 무드 필터 토글 / 리스트 토글 / 장소 추가 화면 / 현재 위치 이동 / `places: [MapPlace]` (현재 미사용 — 후속 정리)
- **클러스터링 관련 코드 추가 금지**. mood 변경은 `HomeMapView`가 받아서 `MapClusteringViewModel.themeChanged`로 라우팅
- 현재 `HomeMapView`가 사용하지 않던 ViewModel을 KAN-82에서 처음 연결

### 6.3 `HomeMapView` 결합 형태 (개념)

```swift
struct HomeMapView: View {
    @StateObject var chrome: HomeMapViewModel              // 무드/토글/추가
    @StateObject var clustering: MapClusteringViewModel    // 클러스터링

    var body: some View {
        NaverMapView(
            spots: clustering.state.spots,                 // [ClusterableSpot] raw
            selectedSpotId: clustering.selectedSpotId,
            onViewportChange: { viewport in
                Task { await clustering.viewportChanged(viewport) }
            },
            onSpotTap: { spotId in
                Task { await clustering.spotMarkerTapped(spotId) }
            }
            // 클러스터 마커 탭은 NMCClusterer 기본 동작(줌인)에 위임 → 콜백 없음
        )
        // ... topBar / trailingControls / MapListToggle (chrome 바인딩)
        .onChange(of: chrome.selectedMood) { _, mood in
            Task { await clustering.themeChanged(mood?.rawValue) }
        }
    }
}

extension MapClusteringViewModel.LoadState {
    var spots: [ClusterableSpot] {
        if case .loaded(let s) = self { return s } else { return [] }
    }
}
```

DI: `AppContainer.registerDependencies()`에 `ClusteringServiceProtocol`만 신규 등록(한 줄) — `SpotServiceProtocol`은 기존 등록 재사용. `getClusteringService()` MainActor 헬퍼는 `ClusteringServiceProtocol.swift` 같은 파일에 둠 (기존 컨벤션).

---

## 7. 외부 앱 / 시스템 연동

**없음** — 본 화면은 인앱 `NMFMapView` 안에서 모두 처리. 네이버 지도 외부앱(nmap://) 호출은 본 티켓 범위 밖.

---

## 8. 화면별 정밀 사양

### 8.1 핀 종류와 시각 사양

| 종류 | 형태 | 배경 | 아이콘/텍스트 | 비고 |
|---|---|---|---|---|
| 일반 클러스터 핀 | 동그란 원형 | `sunsetOrange` solid | 클러스터 개수 텍스트 (`body(.small(.bold))`, `#FFFFFF`) | 큐레이션 스팟 묶음 |
| my 클러스터 핀 | 동그란 원형 | **LinearGradient (위→아래)** — `#000000` opacity 0 → `#000000` opacity 0.7 | `Maps/icPhoto` + 타이틀 (`body(.small(.bold))`, `#FFFFFF`) | my spot 묶음 표시 |
| 단일 스팟 마커 | 동그란 원형 | (my 클러스터와 동일한 그라데이션 추정) <!-- TODO: §11 Figma 검증 시 컨테이너 형태 확인 --> | `Maps/icPhoto` (에셋 재사용) | 클러스터링 해제 후 개별 핀 |
| 선택된 마커 | 단일 스팟 마커 + 보더 | 동일 | 동일 | **border `sunsetOrange` 4px** |

### 8.2 상태 전이

```
viewport 변경 → debounce → /clustering 호출 (서버는 viewport 영역 spots만 필터링하여 반환)
    ↓
응답 [ClusterableSpot] 도착 → ViewModel state.loaded → NaverMapView가 NMCClusterer에 주입
    ↓
NMCClusterer가 클라이언트 사이드 클러스터링 수행
    · 줌 레벨이 임계값 미만 → 클러스터 마커 표시 (sunsetOrange / 검정 그라데이션 등)
    · 줌 레벨이 임계값 이상 → 리프 마커 표시 (자동 해제)
    · 클러스터 마커 탭 → 해당 영역 줌인 (NMCClusterer 기본 동작)
    ↓
리프 마커 탭 → 선택 상태 (sunsetOrange 4px border) → spotMarkerTapped → spot 상세 진입
```

> 줌 임계값은 `NMCBuilder.minClusteringZoom` 등 NMCClusterer 옵션으로 처리. Phase A 시점엔 기본값 사용, Phase C 시각 검증에서 §8.1 디자인 매칭 보면서 조정.

---

---

## 9. 디자인 시스템 추가 — **에셋 입력 매트릭스 (Gate 4)**

> **이 두 매트릭스가 모두 채워진 다음에야 §10 Phase A를 시작한다.** 미채움 상태로 Phase A 진입 금지.
> 현재 Figma·에셋이 아직 합의 전이므로 이 섹션은 **Phase A 차단 상태**. 합의되는 즉시 본 표를 채운 뒤 작업 시작.

### 9.1 컬러 매트릭스

| 토큰명 | Figma node | hex (Light) | hex (Dark) | 용도 |
|---|---|---|---|---|
| `UIAsset.Colors.sunsetOrange` | <!-- TODO: 정확한 node-id --> | (기존 토큰 재사용) | (기존 토큰 재사용) | 일반 클러스터 핀 배경 / 선택 마커 보더 4px |
| `Color.white` (`#FFFFFF`) | — | `#FFFFFF` | `#FFFFFF` | 클러스터 개수 텍스트, my 클러스터 타이틀 |
| my 클러스터 그라데이션 | <!-- TODO --> | `#000000 alpha 0 → #000000 alpha 0.7`, **방향 top→bottom** | 동일 (모드 무관 추정) | my 클러스터 / 단일 스팟 마커 배경 (LinearGradient로 직접 구성, 토큰화 없이 인라인) |

> `sunsetOrange.colorset`는 이미 존재 → 신규 컬러 추가 없음. 그라데이션은 토큰이 아니라 view 안에서 `LinearGradient(colors: [.black.opacity(0), .black.opacity(0.7)], ...)` 형태로 직접 구성한다.
>
> 추가가 필요한 신규 컬러가 생기면 `Resources/DesignSystem/Colors.xcassets`에 colorset 추가 → `tuist generate` 시 `UIAsset.Colors.*`에 자동 반영.

### 9.2 아이콘/이미지 매트릭스

| 에셋명 | Figma node | export 포맷 | 사이즈 (1x/2x/3x) | 용도 |
|---|---|---|---|---|
| `Maps/icPhoto` | <!-- TODO: 정확한 node-id --> | (기존 자산 재사용) | (기존 자산 재사용) | my 클러스터 핀 내부 아이콘 |
| 클러스터 핀 배경 (원형) | <!-- TODO --> | — | — | SwiftUI `Circle` + fill로 구성하면 별도 에셋 불필요. Figma 디자인이 단순 원형이면 코드로 그림 |
| 단일 스팟 마커 | <!-- TODO --> | (기존 자산 재사용) | (기존 자산 재사용) | 클러스터링 해제 후 표시되는 개별 핀. **`Maps/icPhoto` 동일 재사용** (my 클러스터와 같은 아이콘) |

> 모든 핀 아이콘이 `Maps/icPhoto`로 통일 → **신규 이미지 에셋 등록 0건**.

### 9.3 타이포 매핑 (사용한 토큰만)

| 사용처 | 토큰 | 폴백 |
|---|---|---|
| 일반 클러스터 핀 — 개수 텍스트 | `PickflowTypography.body(.small(.bold))` | system bold |
| my 클러스터 핀 — 타이틀 | `PickflowTypography.body(.small(.bold))` | system bold |

> 매트릭스 채움 자가 점검:
> - [ ] §9.1, §9.2가 비어 있지 않다
> - [ ] 각 행이 실제 Figma 노드를 가리키고 hex/사이즈가 명시되어 있다
> - [ ] 누락된 토큰이 `<!-- TODO -->`가 아니라 실제 값으로 채워졌다

위 3개 모두 통과해야 Phase A 진입.

---

## 10. TDD A→B→C 오케스트레이션 (Gate 1)

> **A → B → C는 직렬이다. 단계 건너뛰기·병렬화·역순 모두 금지.**
> 각 단계의 진입/작업/종료 디테일은 리프 문서에서 봄. 이 섹션은 **순서와 게이트만** 명시한다.

```
§9 에셋 매트릭스 (Gate 4)
        ↓
Phase A — ViewModel TDD (Gate 1A)
  · 진입: §3, §6, §9 모두 확정 (스텁이라도 protocol 시그니처 고정)
  · 작업: viewport 변경/debounce/탭/실패 케이스 RED → GREEN, SwiftUI 뷰 0줄
  · 종료: ViewModel 테스트 100% green, 뷰 파일 0개, Mock 서비스로 검증
  · 가이드: docs/phases/phase-a-viewmodel-tdd.md ← Phase A 들어갈 때 읽기
        ↓
Phase B — ui-test-cases.md (Gate 1B + Gate 2)
  · 진입: Phase A 종료 조건 통과
  · 작업: docs/KAN-82/ui-test-cases.md 8컬럼 표 작성
  · 종료: TODO 0개, 행마다 스냅샷 파일명 결정
  · 가이드: docs/phases/phase-b-ui-cases.md ← Phase B 들어갈 때 읽기
        ↓
Phase C — Snapshot + UI (Gate 1C + Gate 3)
  · 진입: Phase B 종료 조건 통과
  · 작업: swift-snapshot-testing 케이스 RED → SwiftUI 뷰 / NMFMarker → GREEN
  · 종료: 매트릭스 전 케이스 green, Figma 비교 루프 1회
  · 가이드: docs/phases/phase-c-snapshot.md ← Phase C 들어갈 때 읽기
```

> 각 Phase에 **들어갈 때** 해당 리프 문서를 read한다. 미리 다 읽어두지 않는다 — 단계 격리가 게이트의 본체다.

---

## 11. UI 검증 루프 (Figma 노드별 비교, Phase C 마무리)

| 컴포넌트 | Figma node-id | 확인 항목 |
|---|---|---|
| 일반 클러스터 핀 | <!-- TODO --> | `sunsetOrange` 배경, 흰색 개수 텍스트, 사이즈(개수 구간별 변화 여부) |
| my 클러스터 핀 | <!-- TODO --> | 검정 그라데이션(0%→70%), `icPhoto` 아이콘, 흰색 타이틀 |
| 단일 스팟 마커 | <!-- TODO --> | `Maps/icPhoto` + 검정 그라데이션 컨테이너 형태 확인 |
| 선택된 단일 마커 | <!-- TODO --> | `sunsetOrange` 4px border, 아이콘/그라데이션은 동일 |
| 지도 전체 화면 (루트) | `908:18395` | 핀 배치, 카메라 영역, 줌 레벨 전이 |

각 노드 조회: `mcp__claude_ai_Figma__get_design_context` / `get_screenshot` (fileKey `LyduUVMjsQi0qyUsENriR5`).

---

## 12. 디버그 진입점

```swift
@State private var isMapClusteringPresented = false

Button("지도 클러스터링 열기") { isMapClusteringPresented = true }
    .fullScreenCover(isPresented: $isMapClusteringPresented) {
        // AppContainer에서 protocol 구현 resolve
        MapClusteringContainerView()
    }
```

> 또는 기존 `HomeMapView`의 디버그 토글에 클러스터링 모드 스위치를 추가하는 안도 가능. Phase A 진입 전 결정.

---

## 13. 논의 포인트 MD

`docs/KAN-82/map-clustering-discussion.md` — 후속 합의 필요 항목.

확정되어야 다음 단계 진입 가능한 항목:
- ~~(a) Figma 파일 키 + 루트 노드~~ ✅ 2026-05-08 확정 (`LyduUVMjsQi0qyUsENriR5` / `908:18395`). **컴포넌트별 node-id 매핑은 여전히 TODO** → §11 채움 필요
- ~~(b) 에셋 매트릭스~~ ✅ 2026-05-08 확정 — 모든 핀 아이콘 `Maps/icPhoto` 통일, 컬러는 `sunsetOrange` 재사용, 타이포 `body(.small(.bold))`. **신규 에셋 등록 0건**
- (c) **viewport 직렬화 포맷** — `bbox=lat1,lng1,...` vs `topLeft.lat=...&topLeft.lng=...` — §3 확정
- ~~(d) `ClusteringExampleView` 처리~~ ✅ 2026-05-11 확정 — **삭제**. KAN-82 NMC SDK 통합 학습 통제군으로 활용 후 정리
- ~~(e) `HomeMapViewModel` ↔ `MapClusteringViewModel` 책임 분리~~ ✅ 2026-05-08 확정 — **병행 VM (분리)**. `HomeMapViewModel`은 chrome(필터/토글/추가/현재위치) 그대로, `MapClusteringViewModel`이 viewport 기반 spot 조회 전담. `HomeMapView`에서 합류
- (f) **`ClusterableSpot` 응답 모델** 서버 합의 (§5는 가설 — id + coordinate + 메타). NMCClusterer가 받을 수 있는 양식이면 됨
- ~~(g) 클러스터링 해제 트리거~~ 2026-05-08 정정: **NMCClusterer 기본 동작에 위임** (줌 임계 자동 / 클러스터 탭 줌인 모두 라이브러리 차원). ViewModel/별도 트리거 코드 없음
- ~~(h) my 클러스터 그라데이션 방향~~ ✅ 2026-05-08 확정 — **위→아래**, alpha 0 → 0.7
- (i) **NMCClusterer 옵션 튜닝** — `minClusteringZoom`, `screenDistance` 등은 Phase C 시각 검증에서 §8.1 디자인 매칭 보면서 조정
- (j) **debounce 튜닝** — 2026-05-09 결정: 책임을 NaverMapView 측으로 이동 (ViewModel 시간 의존 테스트 회피). 인터벌 수치(예: 300ms)는 Phase C 시뮬 동작 보면서 조정

---

## 14. 마감 체크리스트

각 Phase 리프 문서에 단계별 종료 조건이 있다. 여기서는 **PR 머지 직전 한 번 더 확인할 게이트만** 모은다.

**게이트 통과**
- [ ] Gate 1 (TDD A→B→C 직렬): 단계 순서 위반 없음
- [ ] Gate 2 (`ui-test-cases.md`): TODO 0개, 8컬럼 채움
- [ ] Gate 3 (swift-snapshot-testing): 매트릭스 전 케이스 green, `__Snapshots__/` PR 첨부, record 블라인드 덮어쓰기 0건
- [ ] Gate 4 (에셋 매트릭스): §9.1·§9.2 채움 후에 Phase A 시작했음

**일반**
- [ ] `SWIFT_STRICT_CONCURRENCY: complete` 빌드 경고/에러 0
- [ ] §11 Figma 비교 루프 1회 이상
- [ ] §12 디버그 진입점에서 시뮬레이터 동작 확인 (스텁 fixture로 핀 표시되는지)
- [ ] protocol 다형성 검증: ViewModel 테스트가 Mock으로 100% 통과하는지 (실서버 의존 0)
- [ ] `docs/KAN-82/map-clustering-discussion.md` 작성

> 단계 내부 체크리스트(예: "Phase A 종료 조건")는 해당 리프 문서를 본다. 여기 중복으로 박지 않는다.

---

## 15. 작업 순서 요약

```
0. §0~§8 합의 → §9 에셋 매트릭스 채움 (Gate 4)
   ↳ 현재 미합의 항목 (Phase A 진입 비차단):
     - §11 컴포넌트별 Figma node-id (Phase C에서 채워도 됨)
     - §13 (c) viewport 직렬화 포맷 (실서버 구현 시점에 확정, Mock은 `Viewport` 모델 그대로 사용)
     - §13 (f) `ClusterableSpot` 메타 필드 (서버 합의 시 §5 갱신 — protocol 시그니처 동일 유지)
     - §13 (i) NMCClusterer 옵션 튜닝 (Phase C에서 시각 매칭하며 조정)
   ↳ §9 에셋(컬러/아이콘/타이포)는 **전부 기존 토큰 재사용으로 해소** — 신규 등록 0건
   ↳ §13 (a)/(b)/(e)/(h) 해소, (d)/(g) 정정 — **Gate 4 통과, Phase A 진입 가능**
        ↓
1. docs/phases/phase-a-viewmodel-tdd.md 읽기 → Phase A 수행 (Gate 1A)
   ↳ Mock 서비스로 viewport→clusters 흐름 / debounce / 실패 케이스
        ↓
2. docs/phases/phase-b-ui-cases.md 읽기 → Phase B 수행 (Gate 1B + 2)
   ↳ ui-test-cases.md 8컬럼 작성
        ↓
3. docs/phases/phase-c-snapshot.md 읽기 → Phase C 수행 (Gate 1C + 3) → §11 Figma 루프
        ↓
4. §12 디버그 검증 → §13 논의 포인트 → §14 통과 → PR
```

> 순서를 어겼다면 PR 본문에 어디서 거꾸로 갔는지 명시. 단계 건너뛰기는 회귀 비용으로 직결된다.
