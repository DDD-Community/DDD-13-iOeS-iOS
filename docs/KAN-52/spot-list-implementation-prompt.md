# [KAN-52] 스팟 리스트 화면 구현 통합 프롬프트

> **이 프롬프트의 사용법**: `screen-tdd-prompt` 스킬이 템플릿을 복제·치환해서 저장한 단일 구현 프롬프트.
>
> **방법론은 여기 없다.** TDD 단계별 디테일은 단계 진입 시 리프 문서를 읽는다:
> - Phase A: `docs/phases/phase-a-viewmodel-tdd.md`
> - Phase B: `docs/phases/phase-b-ui-cases.md`
> - Phase C: `docs/phases/phase-c-snapshot.md`

---

## 0. 작업 컨텍스트 (선결 정보)

**브랜치**: `feature/KAN-52` (develop 분기, 워크트리 `DDD-13-iOeS-iOS-KAN52`)
**티켓**: https://dddios1.atlassian.net/browse/KAN-52
**전체 화면 Figma**: `https://www.figma.com/design/LyduUVMjsQi0qyUsENriR5/?node-id=908-19343`
**필터 UI Figma**: `https://www.figma.com/design/LyduUVMjsQi0qyUsENriR5/?node-id=908-19400`

**프로젝트 가정**:
- SwiftUI + MVVM, Tuist, `SWIFT_STRICT_CONCURRENCY: complete`
- DI: `AppContainer.shared.registerDependencies()` → `getXxxService()` MainActor 헬퍼
- DesignSystem: `UIAsset.Colors.*`(`Resources/DesignSystem/Colors.xcassets`), `.pretendard(...)`(`Common/DesignSystem/Fonts/PickflowTypography.swift`)
- 테스트 타겟 `PickflowTests`
- 선례: KAN-51(`Feature/SpotDetail/*`)
- 진입점: `HomeMapView`의 `MapListToggle`이 `.map` ↔ `.list` 전환

**개발 서버 상태**: 아직 미오픈. **Preview/Mock 데이터로 작성**, 실 통신은 endpoint만 정의하고 ViewModel은 `SpotListServiceProtocol`에 의존하도록 추상화.

---

## 1. 스코프

**구현 범위**:
- 2열 Pinterest 스타일 스팟 리스트 화면 (`SpotListView`)
- 무드 타입 필터: 노을 / 윤슬 — `MoodFilter`(HomeMapView) 또는 기존 `SpotTheme` 재사용 결정 필요(§13)
- 정렬: 가까운 순(distance asc) / 북마크 순(bookmark desc)
- 셀: 무드 타입 이미지, 거리(`0000.0km` 포맷), 스팟 이름, 무드 텍스트, 북마크 수, 북마크 토글
- `MapListToggle`과 연동, **무드 필터 상태는 지도-리스트 공유**
- 비로그인 + 북마크 탭 → `LoginPromptPopup`(`Feature/SpotDetail/Components/LoginPromptPopup.swift`) 띄움
- 위치 권한 미허용 시 화면 자체 미표시 (현재 위치 없이는 리스트 노출 X)
- 페이지네이션: `page` 0-based, `hasNext` 기반 무한 스크롤

**범위 밖**:
- 스팟 상세 화면 진입
- 검색
- 다중 무드 동시 선택

---

## 2. 핵심 정책 결정 (사용자 확정)

| # | 항목 | 결정 |
|---|---|---|
| 1 | 무드 필터 동작 | 단일 토글(같은 무드 재탭 시 해제), `nil`이면 전체 |
| 2 | 정렬 기본값 | **가까운 순** |
| 3 | 거리 포맷 | `0000.0km` (소수점 1자리, 단위 km 고정) — API의 `distanceKm` 그대로 표시 |
| 4 | 위치 권한 미허용 시 | **리스트 화면 미표시** (`MapListToggle`로 진입하더라도 안내 + 빈 컨텐츠) |
| 5 | 비로그인 시 북마크 탭 | `LoginPromptPopup` 표시 (취소 / 간편 로그인하기) |
| 6 | 무드 필터 상태 | **지도와 공유**: 지도에서 `노을` 선택하면 리스트도 `노을`, 역도 동일. SourceOfTruth 1개 |
| 7 | 페이지네이션 | 서버 cursor 없이 `page`(int, 0-based) + `hasNext`(bool). 무한 스크롤 |

---

## 3. API 매핑

### 3.1 리스트 조회 — `GET /v1/spots` (인증 불필요)

**Query**:
| 파라미터 | 타입 | 필수 | 기본 | 설명 |
|---|---|---|---|---|
| page | int | ❌ | 0 | 0-based 페이지 |
| theme | String | ❌ | - | `SS`(노을) / `YS`(윤슬) |
| latitude | Double | ❌ | - | 거리 계산용 |
| longitude | Double | ❌ | - | 거리 계산용 |

**Response**:
```json
{
  "success": true, "code": "S000", "message": "성공",
  "data": {
    "spots": [
      { "spotId": 1, "name": "스팟명", "theme": "SS",
        "thumbnailUrl": "https://...", "distanceKm": 1.23 }
    ],
    "page": 0, "hasNext": true
  }
}
```
- `latitude`/`longitude` 미전달 시 `distanceKm = null`
- **FIXME(BE-API): 응답에 `bookmarkCount` / `isBookmarked` 없음**. 셀 스펙(북마크 수/토글)을 채우려면 BE 추가가 필요하다. 임시 처리: ViewModel에서 `isBookmarked = false`, `bookmarkCount = nil`로 초기화하고 UI는 `nil`이면 카운트 숨김. 추후 응답 확정 시 모델/매핑만 수정.
- **FIXME(BE-API): 정렬(`nearest`/`bookmark`) 쿼리 파라미터 없음**. "가까운 순"은 서버가 거리 기준 정렬해 준다고 가정(BE 확인 필요). "북마크 순"은 BE에 `sort` 파라미터 추가 또는 응답에 `bookmarkCount` 포함되면 클라 정렬. 현 단계에서는 ViewModel에 `sort` 인터페이스만 노출하고 실제 호출은 동일, FIXME로 표기.

### 3.2 북마크 — 기존 재사용

| UI 동작 | 메서드 |
|---|---|
| 북마크 ON | `BookmarkService.addBookmark(spotId:)` (`BookmarkEndpoint.add`) |
| 북마크 OFF | `BookmarkService.deleteBookmark(spotId:)` (`BookmarkEndpoint.delete`) |

낙관적 업데이트 + 실패 시 롤백.

---

## 4. 신규/수정 파일 목록

**신규**
```
Pickflow/Sources/Feature/SpotList/
  SpotListView.swift
  SpotListViewModel.swift
  Components/
    SpotListCell.swift
    SpotListSortSelector.swift          // 가까운 순 / 북마크 순
    PinterestTwoColumnLayout.swift      // 2열 비대칭 (LazyVStack × 2)
    SpotListEmptyView.swift
    SpotListUnauthorizedLocationView.swift  // 위치 권한 미허용 안내
  Preview/
    SpotListMockData.swift              // BE 미오픈, preview/snapshot용

Pickflow/Sources/Core/Services/
  Models/
    SpotListItem.swift                  // 리스트 응답 전용 모델
  Endpoints/
    SpotListEndpoint.swift              // GET /v1/spots
  Protocols/
    SpotListServiceProtocol.swift
  SpotListService.swift

PickflowTests/Feature/SpotList/
  SpotListViewModelTests.swift
  SpotListViewSnapshotTests.swift

docs/KAN-52/
  spot-list-implementation-prompt.md
  ui-test-cases.md
  spot-list-discussion.md
```

**수정**
- `Pickflow/Sources/Feature/Map/HomeMapView.swift` — 리스트 모드일 때 `SpotListView` 렌더링. 무드 필터 상태를 상위 컨테이너로 끌어올려 공유(§13(a)). `MoodFilter` ↔ `SpotTheme` 매핑 결정 후 통일.
- `Pickflow/Sources/Core/DI/AppContainer.swift` — `SpotListServiceProtocol` 등록
- (필요 시) `Pickflow/Sources/Core/Services/Models/Spot.swift` — `SpotTheme`에 API 코드(SS/YS) 매핑 헬퍼 추가

---

## 5. 모델 정의 가이드

```swift
struct SpotListItem: Codable, Sendable, Identifiable, Equatable {
    let spotId: Int64
    let name: String
    let theme: SpotTheme            // SS/YS 디코딩 매핑 필요 (아래)
    let thumbnailUrl: String?
    let distanceKm: Double?         // 위경도 미전달 시 nil

    var id: Int64 { spotId }
}

struct SpotListPage: Codable, Sendable, Equatable {
    let spots: [SpotListItem]
    let page: Int
    let hasNext: Bool
}

// FIXME(BE-API): 응답에 bookmarkCount/isBookmarked 추가되면 SpotListItem에 필드 확장
```

**SpotTheme 매핑 이슈**:
- 기존 `enum SpotTheme: String { case sunset = "노을", reflection = "윤슬" }` 의 rawValue는 한글.
- 리스트 API는 `"SS"` / `"YS"` 코드를 사용 → 그대로 디코딩하면 실패.
- 해법(둘 중 선택, §13(b)):
  - (1) `SpotListItem` 전용 `init(from:)` 커스텀 디코딩에서 `SS→sunset`, `YS→reflection` 매핑
  - (2) `SpotTheme`에 `apiCode: String { "SS"/"YS" }` 양방향 헬퍼 추가 후, 전용 wrapper 사용

JSONDecoder는 `convertFromSnakeCase` 전역 적용 → `spotId`, `thumbnailUrl`, `distanceKm` 매핑은 자동.

---

## 6. ViewModel 시그니처

```swift
@MainActor
final class SpotListViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(items: [SpotListItem], hasNext: Bool)
        case empty
        case failed(String)
        case locationUnauthorized       // 위치 권한 미허용 → 화면 미표시
    }

    @Published private(set) var state: LoadState = .idle
    @Published var selectedTheme: SpotTheme? = nil   // 지도와 공유 (§13(a))
    @Published var sort: SpotListSort = .nearest     // 기본: 가까운 순
    @Published private(set) var bookmarkStates: [Int64: Bool] = [:]  // FIXME(BE-API): 응답에 포함되면 제거

    init(
        spotListService: SpotListServiceProtocol,
        bookmarkService: BookmarkServiceProtocol,
        locationService: LocationServiceProtocol,
        loginStateProvider: LoginStateProviding   // FIXME: 기존 로그인 상태 조회 방식과 매칭
    )

    func onAppear() async
    func themeTapped(_ theme: SpotTheme) async       // 같은 무드 재탭 → nil
    func sortChanged(_ sort: SpotListSort) async     // FIXME(BE-API): 정렬 파라미터 미지원
    func loadNextPageIfNeeded(currentItem: SpotListItem) async
    func bookmarkTapped(_ spotId: Int64) async       // 비로그인이면 showLoginPrompt = true
    @Published var showLoginPrompt: Bool = false
}

enum SpotListSort: String, Sendable, CaseIterable {
    case nearest    // 가까운 순
    case bookmark   // 북마크 순  (FIXME: BE 미지원)
}
```

DI: `AppContainer.registerDependencies()`에 `SpotListServiceProtocol` 등록.

---

## 7. 외부 앱 / 시스템 연동

없음 (위치 권한은 iOS 시스템 권한 only).

---

## 8. 화면별 정밀 사양

### 8.1 Pinterest 2열 그리드
- 2개 컬럼, 컬럼 간 spacing FIXME(Figma 908:19343 측정)
- 카드 높이는 썸네일 종횡비 가변. `LazyVGrid`는 동일 행 정렬 강제 → 핀터레스트 효과 X. **두 개의 `LazyVStack`을 `HStack`에 나란히 배치**하고 인덱스 짝/홀로 분배.
- 무한 스크롤: 마지막에서 N개 전 셀이 보이면 `loadNextPageIfNeeded` 호출. `hasNext == false`면 호출 안 함.

### 8.2 셀 레이아웃
```
┌──────────────┐
│  thumbnail   │  ← 종횡비 가변, mood overlay 좌상단(sunset/sparklingRipple)
│              │
├──────────────┤
│ name         │  ← 1줄 truncate
│ 무드텍스트     │  ← "노을" or "윤슬"
│ 📍 1.2km · ♡ 12│  ← distanceKm nil이면 거리 숨김 / bookmarkCount nil이면 카운트 숨김
└──────────────┘
```
- 북마크 버튼 hit target ≥ 44pt
- 거리 포맷: `String(format: "%.1fkm", distanceKm)` (정책 §2)

### 8.3 필터/정렬 바
- 무드 capsule: `HomeMapView.moodCapsuleButton`과 동일 시각 토큰 — 공용 컴포넌트로 추출 권장 (§13(c))
- 정렬 셀렉터: FIXME(Figma 908:19400 형태 확인 — chip / dropdown / segmented)

### 8.4 위치 권한 미허용 처리
- `LocationService.authorizationStatus()`가 `.denied` / `.restricted`면 `state = .locationUnauthorized`
- 화면에 컨텐츠 렌더링 안 하고 안내 + 설정 이동 버튼만 표시

---

## 9. 디자인 시스템 추가 — **에셋 입력 매트릭스 (Gate 4)**

> Figma MCP가 현 환경에서 미가용. **확정값은 기존 자산 재사용으로 채웠고, Figma 측정 필요분은 FIXME로 마킹**. Phase A 진입 전 FIXME를 실제 값으로 치환할 것.

### 9.1 컬러 매트릭스

| 토큰명 | Figma node | hex (Light/Dark) | 용도 |
|---|---|---|---|
| `themeSunset` (기존) | — | 기존 정의 | 노을 셀/배지 |
| `themeReflection` (기존) | — | 기존 정의 | 윤슬 셀/배지 |
| `sunsetOrange` (기존) | — | 기존 정의 | 활성 보더/주요 액션 |
| `gray0` ~ `gray100` (기존) | — | 기존 정의 | 배경/텍스트 계조 |
| `surfaceChip` (기존) | — | 기존 정의 | 필터 capsule 배경 |
| `spotListCardBg` | FIXME(Figma 908:19343) | FIXME | 셀 배경 (gray95로 추정, 확정 전 사용 자제) |
| `spotListDistanceText` | FIXME(Figma 908:19343) | FIXME | 거리/카운트 텍스트 |
| `spotListDivider` | FIXME(Figma 908:19343) | FIXME | 셀 내부 구분선 (있다면) |

추가 후 `tuist generate` 시 `UIAsset.Colors.*`에 자동 추가됨.

### 9.2 아이콘/이미지 매트릭스

| 에셋명 | Figma node | export | 사이즈 | 용도 |
|---|---|---|---|---|
| `icBookmarkBorder` (기존) | — | — | — | 셀 북마크 OFF |
| `icBookmarkFilled` (기존) | — | — | — | 셀 북마크 ON |
| `sunset` (기존) | — | — | — | 셀 mood overlay + capsule |
| `sparklingRipple` (기존) | — | — | — | 셀 mood overlay + capsule |
| `icLocationOn` (기존) | — | — | — | 거리 prefix 후보 (확정 전 FIXME) |
| sortIcon | FIXME(Figma 908:19400) | SVG/PDF | 16/32/48 | 정렬 셀렉터 |
| spotListEmpty | FIXME(Figma 908:19343 빈 상태 영역) | SVG/PDF | — | 빈 상태 일러스트 |
| locationDenied | FIXME(Figma 권한 안내 영역) | SVG/PDF | — | 위치 권한 미허용 안내 |

### 9.3 타이포 매핑

`Common/DesignSystem/Fonts/PickflowTypography.swift`의 `.pretendard(...)` 사용.

| 사용처 | 토큰 | 폴백 |
|---|---|---|
| 셀 스팟 이름 | FIXME(Figma 측정 — `.body(.large(.semibold))` 추정) | system |
| 셀 무드 텍스트 | FIXME — `.body(.small)` 추정 | system |
| 셀 거리/북마크 카운트 | FIXME — `.caption` 추정 | system |
| 정렬 라벨 | FIXME | system |
| 빈 상태 / 권한 안내 | FIXME | system |

> 자가 점검:
> - [ ] §9.1 FIXME 모두 실제 값으로 교체
> - [ ] §9.2 FIXME 모두 실제 node-id + export 완료
> - [ ] §9.3 FIXME 모두 실제 토큰으로 교체
>
> 위 3개 모두 통과해야 Phase A 진입.

---

## 10. TDD A→B→C 오케스트레이션 (Gate 1)

> **A → B → C는 직렬이다.** 단계 진입 시 해당 리프 문서를 read.

```
§9 에셋 매트릭스 FIXME 해소 (Gate 4)
        ↓
Phase A — ViewModel TDD (Gate 1A)
  · 진입: §3, §6, §9 확정 (단, BE-API FIXME는 mock service로 대체)
  · 작업:
    - onAppear → 위치권한 확인 → currentLocation → fetchSpots
        · 권한 거부 → .locationUnauthorized
        · 빈 응답 → .empty / 정상 → .loaded(items, hasNext)
        · 실패 → .failed
    - themeTapped(같은 무드 재탭 → nil) → 재호출
    - sortChanged → (FIXME: BE 미지원 시 nearest만 실제 동작, bookmark는 클라 정렬 placeholder)
    - loadNextPageIfNeeded → hasNext 시 page+1
    - bookmarkTapped → 로그인 여부 분기, 낙관적 토글 + 실패 롤백
  · 종료: ViewModel 테스트 100% green, 뷰 파일 0개
        ↓
Phase B — ui-test-cases.md (Gate 1B + Gate 2)
  · docs/KAN-52/ui-test-cases.md 8컬럼 표 작성
  · 케이스: loading / loaded(N=1,짝수,홀수) / empty / failed / locationUnauthorized
           filter: nil/SS/YS  sort: nearest/bookmark  bookmark: on/off
           긴 이름 truncate, 썸네일 nil placeholder, distanceKm nil 숨김
        ↓
Phase C — Snapshot + UI (Gate 1C + Gate 3)
  · swift-snapshot-testing RED → SwiftUI 뷰 → GREEN
  · §11 Figma 비교 루프 1회
```

---

## 11. UI 검증 루프 (Phase C 마무리)

| 컴포넌트 | Figma node-id | 확인 항목 |
|---|---|---|
| 리스트 화면 전체 | 908:19343 | 헤더 + 필터 + 그리드 + 토글 |
| 필터/정렬 바 | 908:19400 | 무드 capsule, 정렬 셀렉터 |
| 셀 | FIXME(Figma) | 썸네일/이름/무드/거리/북마크 |
| 빈 상태 | FIXME(Figma) | 일러스트 + 안내 |
| 로딩 상태 | FIXME(Figma) | 스켈레톤 vs 스피너 |
| 위치 권한 미허용 | FIXME(Figma) | 안내 + 설정 이동 |

조회: `mcp__claude_ai_Figma__get_design_context` / `get_screenshot` (fileKey `LyduUVMjsQi0qyUsENriR5`).

---

## 12. 디버그 진입점

정상 경로는 `HomeMapView`의 `MapListToggle`. 단독 검증용 임시 진입점:

```swift
@State private var isSpotListPresented = false

Button("스팟 리스트 열기") { isSpotListPresented = true }
    .fullScreenCover(isPresented: $isSpotListPresented) {
        SpotListView(viewModel: getSpotListViewModel(mock: true))   // BE 미오픈 → mock
    }
```

`SpotListMockData.swift`에 다양한 상태(empty/loaded/failed/locationDenied) preset 제공. PR 머지 전 `#if DEBUG` 처리.

---

## 13. 논의 포인트 (`docs/KAN-52/spot-list-discussion.md` 별도 작성)

- (a) **무드 필터 SourceOfTruth**: 부모 컨테이너(`HomeView` 신설) vs `AppContainer`/EnvironmentObject. 현재 `HomeMapView`가 `@State`로 들고 있어 토글 시 손실 → 끌어올리기 필요.
- (b) **SpotTheme SS/YS 매핑**: `SpotTheme`에 `apiCode` 헬퍼 추가 vs 리스트 모델 전용 커스텀 디코딩. 전자가 재사용성 ↑.
- (c) **moodCapsuleButton 공용화**: `HomeMapView`에서 추출해 `Common/Components/MoodCapsuleButton.swift`로. 시각 토큰 동일.
- (d) **BE-API gap**: 응답에 `bookmarkCount`/`isBookmarked` 추가 + 정렬 파라미터 추가 요청 (BE 협의).
- (e) **Pinterest 그리드**: 두 LazyVStack vs iOS 16+ custom `Layout`. 전자가 단순, 후자가 동적 재배치 우수.

---

## 14. 마감 체크리스트

**게이트**
- [ ] Gate 1 (TDD A→B→C 직렬)
- [ ] Gate 2 (`ui-test-cases.md` 8컬럼 채움, TODO 0)
- [ ] Gate 3 (swift-snapshot-testing 전 케이스 green, `__Snapshots__/` PR 첨부)
- [ ] Gate 4 (§9 FIXME 해소 후 Phase A 시작)

**일반**
- [ ] `SWIFT_STRICT_CONCURRENCY: complete` 빌드 경고/에러 0
- [ ] §11 Figma 비교 루프 1회
- [ ] §12 디버그 진입점 시뮬 동작 확인
- [ ] `MapListToggle` 실제 진입 경로 검증
- [ ] BE-API FIXME 항목 PR 본문에 명시 + BE 티켓 링크
- [ ] `docs/KAN-52/spot-list-discussion.md` 작성

---

## 15. 작업 순서 요약

```
0. §13 논의 (a)(b)(c) 합의 → §9 FIXME 해소 (Gate 4) → Mock 데이터 작성
        ↓
1. docs/phases/phase-a-viewmodel-tdd.md 읽기 → Phase A (Mock 서비스로 RED→GREEN)
        ↓
2. docs/phases/phase-b-ui-cases.md 읽기 → Phase B (ui-test-cases.md)
        ↓
3. docs/phases/phase-c-snapshot.md 읽기 → Phase C → §11 Figma 루프
        ↓
4. §12 디버그 검증 → §14 통과 → PR (BE-API FIXME는 별도 티켓)
```
