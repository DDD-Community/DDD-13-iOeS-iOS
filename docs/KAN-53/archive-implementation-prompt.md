# [KAN-53] 나의 보관함 화면 구현 통합 프롬프트

> **이 프롬프트의 사용법**: `screen-tdd-prompt` 스킬이 이 템플릿을 복제·치환해서 `docs/KAN-53/archive-implementation-prompt.md`로 저장한다.
>
> **방법론은 여기 없다.** TDD 단계별 디테일은 단계 진입 시 리프 문서를 읽는다:
> - Phase A: `docs/phases/phase-a-viewmodel-tdd.md`
> - Phase B: `docs/phases/phase-b-ui-cases.md`
> - Phase C: `docs/phases/phase-c-snapshot.md`
>
> 본 문서는 **이 화면에만 해당하는 사실**(스코프, API, 정책, 에셋, 컴포넌트 매핑)을 담는다.

---

## 0. 작업 컨텍스트 (선결 정보)

**브랜치**: `feature/KAN-53` (이미 develop에서 분기/체크아웃됨)
**티켓**: https://dddios1.atlassian.net/browse/KAN-53
**전체 화면 Figma**: `https://www.figma.com/design/LyduUVMjsQi0qyUsENriR5/?node-id=873-19709`

**프로젝트 가정 (재탐색 불필요)**:
- SwiftUI + MVVM, Tuist 매니페스트(`Project.swift`)
- 외부 의존성: Alamofire, Swinject, KakaoSDK*, nMapsMap, FirebaseMessaging
- DI: `AppContainer.shared.registerDependencies()` → `getXxxService()` MainActor 헬퍼
- 디자인 시스템: `Resources/DesignSystem/Colors.xcassets` → `UIAsset.Colors.*` 자동 생성, `Common/DesignSystem/Fonts/PickflowTypography.swift`의 `.pretendard(...)` 토큰
- 테스트 타겟 `PickflowTests` 존재 (KAN-51부터). 신규 테스트는 거기에 추가
- `SWIFT_STRICT_CONCURRENCY: complete` — 모든 신규 타입 `Sendable`/`@MainActor` 명시
- 선례: KAN-52(`Feature/SpotList/*`), KAN-54(`Feature/MyProfile/*`)

**기존 스켈레톤 (교체 대상)**:
- `App/CustomTabBarView/DummyViews/SavedHomeView.swift` — dummy placeholder. 본 티켓에서 `ArchiveView`로 대체.
- `Core/Services/Endpoints/ArchiveEndpoint.swift` — `case getImage / uploadImage` 최소 정의. 본 티켓에서 파라미터 추가.

**개발 서버 상태**: 미오픈. `ArchiveMockService`로 구현, endpoint만 정의. FIXME 주석으로 BE 오픈 시 교체 안내.

---

## 1. 스코프

**구현 범위**:
- `ArchiveView` — `ContentView` `.saved` 탭 루트 교체
- **비로그인 상태**: 탭 내에서 카카오/애플 로그인 버튼이 포함된 로그인 유도 화면 (탭 바는 계속 표시)
- **로그인 상태 - 빈 상태**: "마음에 드는 스팟을 발견하셨나요?" + "스팟 둘러보기" 버튼 (탐색 탭으로 이동)
- **로그인 상태 - 스팟 있음**: 가변 높이 헤더(최근 저장 스팟 썸네일 배경) + 스크롤 시 sticky 탭 바
- **두 탭**: "저장된 스팟" (이번 구현 대상) / "나만의 스팟" (placeholder — 탭 헤더만, body는 빈 View)
- **저장된 스팟 탭**: 2열 Masonry 그리드 (`MasonryTwoColumn` 재사용), `SpotListCell` 재사용
- 북마크 해제 → 낙관적 제거 (즉시 리스트에서 삭제, API 실패 시 복원)
- 페이지네이션: `page` 0-based, `hasNext` 기반 무한 스크롤
- 우측 상단 `···` 버튼 (placeholder — 탭에 버튼만 노출, 액션 없음)

**범위 밖**:
- "나만의 스팟" 탭 body 구현 (별도 티켓)
- 스팟 상세 화면 진입
- 보관함 내 검색
- `···` 버튼 실제 기능
- `ArchiveEndpoint.uploadImage` 사용

---

## 2. 핵심 정책 결정 (사용자 확정)

| # | 항목 | 결정 |
|---|---|---|
| 1 | 비로그인 진입 | **탭 내에서 로그인 유도 UI 표시** — "PICKFLOW" 로고 + "보관함 기능을 사용하려면 로그인이 필요해요" + 카카오/애플 버튼. 탭 바는 계속 노출. `AppRootView`에서 강제 redirect 안 함 |
| 2 | 로그인 성공 후 동작 | `LoginView`를 dismiss하고 보관함 데이터 로드 |
| 3 | 북마크 해제 동작 | 낙관적 제거(toggle이 아닌 list remove). API 실패 시 item 복원 + toast |
| 4 | 빈 상태 CTA | "스팟 둘러보기" 버튼 탭 → `ContentView` 탭을 `.explore`로 전환 |
| 5 | 헤더 이미지 | 가장 최근에 저장한 스팟의 `thumbnailUrl`. 스팟이 없으면 회색 단색 배경 |
| 6 | 스크롤 동작 | 헤더(큰 타이틀 포함)는 스크롤 시 축소. "저장된 스팟 / 나만의 스팟" 탭 바는 상단에 sticky |
| 7 | 정렬 | **없음** — 정렬 UI 없이 API 응답 순서 그대로 표시 |
| 8 | 거리 포맷 | `String(format: "%.1fkm", distanceKm)`, nil이면 숨김 (KAN-52 동일) |
| 9 | 위치 권한 | 불필요. `distanceKm`은 API 응답 포함 여부 FIXME(BE 확인) |
| 10 | 페이지네이션 | `page`(int, 0-based) + `hasNext`(bool). 마지막 N개 전 셀 진입 시 다음 페이지 로드 |

---

## 3. API 매핑

| UI 동작 | Endpoint | 비고 |
|---|---|---|
| 화면 진입 / 재시도 | `GET /v1/users/me/archive` (`ArchiveEndpoint.fetchArchive`) | 인증 필요. 응답 형태 FIXME(BE 확인 — `SpotListPage` 재사용 추정) |
| 페이지 추가 로드 | 동일 엔드포인트 `page+1` | `hasNext == false`이면 호출 없음 |
| 북마크 해제 | `DELETE /v1/spots/{spotId}/bookmarks` (`BookmarkEndpoint.delete`) | 기존 `BookmarkService.deleteBookmark(spotId:)` 재사용 |

**FIXME(BE-API)**:
- `GET /v1/users/me/archive` 응답이 `SpotListPage`와 동일한 구조인지 BE 확인 필요
- 응답에 `distanceKm` / `isBookmarked` / `bookmarkCount` 포함 여부
- 비로그인 시 401 응답 여부 (클라에서 토큰 유무로 선처리)

---

## 4. 신규/수정 파일 목록

**신규**
```
Pickflow/Sources/Feature/Archive/
  ArchiveView.swift                     // 메인 뷰 (헤더 + 탭 + 콘텐츠)
  ArchiveViewModel.swift
  Components/
    ArchiveHeaderView.swift             // 가변 높이 이미지 헤더 + 큰 타이틀
    ArchiveTabBar.swift                 // "저장된 스팟" / "나만의 스팟" sticky 탭
    ArchiveEmptyView.swift              // 빈 상태 (스팟 둘러보기 버튼 포함)
    ArchiveSignedOutView.swift          // 비로그인 상태 (PICKFLOW + 로그인 버튼)
  Preview/
    ArchiveMockService.swift            // BE 미오픈. SpotListMockService 패턴 동일

Pickflow/Sources/Core/Services/
  Protocols/
    ArchiveServiceProtocol.swift
  ArchiveService.swift

PickflowTests/Helpers/
  ArchiveTestDoubles.swift              // MockArchiveService (callCount, stubResult)
PickflowTests/
  ArchiveViewModelTests.swift
  ArchiveSnapshotTests.swift

docs/KAN-53/
  archive-implementation-prompt.md     ← 본 문서
  ui-test-cases.md
```

**수정**
- `Pickflow/Sources/App/ContentView.swift` — `.saved` 탭 `SavedHomeView()` → `ArchiveView(viewModel:, onNavigateToExplore:)` 교체. 빈 상태 CTA 콜백 주입.
- `Pickflow/Sources/App/AppContainer.swift` — `ArchiveServiceProtocol` 등록 (임시 `ArchiveMockService`, FIXME)
- `Pickflow/Sources/Core/Services/Endpoints/ArchiveEndpoint.swift` — `fetchArchive(page:)` 케이스 추가

---

## 5. 모델 정의 가이드

```swift
// ArchiveServiceProtocol.swift
protocol ArchiveServiceProtocol: Sendable {
    // FIXME(BE-API): 응답이 SpotListPage와 다른 구조라면 ArchivePage 별도 정의
    func fetchArchive(page: Int) async throws -> SpotListPage
}

enum ArchiveTab: Hashable, CaseIterable {
    case savedSpots   // "저장된 스팟"
    case mySpots      // "나만의 스팟" — KAN-53 범위 밖 (placeholder)

    var title: String {
        switch self {
        case .savedSpots: "저장된 스팟"
        case .mySpots: "나만의 스팟"
        }
    }
}

@MainActor
func getArchiveService() -> ArchiveServiceProtocol { /* DIContainerHolder 패턴 */ }
```

`SpotListPage` / `SpotListItem` 모델 재사용. JSONDecoder `convertFromSnakeCase` 전역 적용.

---

## 6. ViewModel 시그니처

**선례**: `MyProfileViewModel` 패턴 그대로 따른다 (`Feature/MyProfile/MyProfileViewModel.swift`).
- 로그인 판정: `authService.currentAuthState()` (토큰 직접 확인 아님)
- 로그인 실행: `socialLoginService.signInWithKakao/Apple()` 직접 호출 (LoginView 화면 전환 없음)
- 성공 후: `onAppear()` 재호출로 데이터 로드

```swift
@MainActor
final class ArchiveViewModel: ObservableObject {
    enum LoadState: Equatable {
        case signedOut                               // 비로그인 — ArchiveSignedOutView 표시
        case loading                                 // 로그인 후 데이터 로드 중
        case loaded(items: [SpotListItem], hasNext: Bool)
        case empty                                   // "스팟 둘러보기" CTA
        case failed(String)
    }

    @Published private(set) var state: LoadState = .loading
    @Published private(set) var selectedTab: ArchiveTab = .savedSpots
    @Published private(set) var isLoadingNextPage: Bool = false
    @Published private(set) var isLoginLoading: Bool = false
    @Published private(set) var loginError: String?
    @Published var toast: String?

    init(
        archiveService: ArchiveServiceProtocol,
        bookmarkService: BookmarkServiceProtocol,
        authService: AuthServiceProtocol,
        socialLoginService: SocialLoginServiceProtocol
    )

    func onAppear() async              // authService.currentAuthState() → .signedOut / fetchArchive
    func signInWithKakao() async       // MyProfileViewModel.signInWithKakao() 동일 패턴
    func signInWithApple() async       // MyProfileViewModel.signInWithApple() 동일 패턴
    func tabChanged(_ tab: ArchiveTab)
    func loadNextPageIfNeeded(currentItem: SpotListItem) async
    func bookmarkTapped(_ spotId: Int64) async   // 낙관적 제거 + 실패 복원
}
```

**`ContentView`에서 탭 전환 콜백 주입**:
```swift
case .saved:
    NavigationStack(path: $savedPath) {
        ArchiveView(
            viewModel: ArchiveViewModel(
                archiveService: getArchiveService(),
                bookmarkService: getBookmarkService(),
                authService: getAuthService(),
                socialLoginService: getSocialLoginService()
            ),
            onNavigateToExplore: { selectedTab = .explore }
        )
    }
```

---

## 7. 외부 앱 / 시스템 연동

없음.

---

## 8. 화면별 정밀 사양

### 8.1 전체 레이아웃 구조

```
┌─────────────────────────────┐
│ ArchiveHeaderView            │  ← 가변 높이, 썸네일 배경 + "나의 보관함" 대형 타이틀
│ (스크롤 시 축소 → NavBar 타이틀)│    우측 상단: ··· 버튼 (placeholder)
├─────────────────────────────┤
│ ArchiveTabBar (sticky)       │  ← "저장된 스팟" | "나만의 스팟" 탭
├─────────────────────────────┤
│ 콘텐츠 영역 (스크롤)           │
│  - signedOut:  ArchiveSignedOutView
│  - empty:      ArchiveEmptyView
│  - loaded:     MasonryTwoColumn + SpotListCell
│  - loading:    SpotListLoadingView (재사용)
│  - failed:     SpotListFailedView (재사용)
└─────────────────────────────┘
```

### 8.2 ArchiveHeaderView

- 배경: `thumbnailUrl`이 있으면 AsyncImage (최근 저장 스팟). 없으면 `gray70` 단색.
- 하단 좌측: "나의 보관함" — 큰 타이틀 (`pretendard(.display)` 추정, FIXME Figma 측정)
- 스크롤 연동: `ScrollView` offset 감지 → offset < 0 시 헤더 병렬 이동 / NavigationBar 타이틀 fade-in
- 구현: `GeometryReader` + `PreferenceKey` offset 트래킹, 또는 iOS 16+ `navigationBarTitleDisplayMode(.large)` 활용 검토

### 8.3 ArchiveTabBar (sticky)

```
┌─────────────────┬─────────────────┐
│  저장된 스팟      │   나만의 스팟    │
│  ─────────      │                 │
└─────────────────┴─────────────────┘
```
- 활성 탭: 탭 이름 + 하단 white underline, 텍스트 white
- 비활성 탭: 텍스트 `gray50`
- 스크롤 시 NavigationBar 아래 고정 (`safeAreaInset` 또는 sticky header 기법)

### 8.4 저장된 스팟 — 스팟 있음 (loaded)

`MasonryTwoColumn` + `SpotListCell` 재사용:

```swift
MasonryTwoColumn(items: items, onAppearItem: onAppearItem) { item in
    SpotListCell(
        item: item,
        isBookmarked: true,        // 보관함 = 항상 북마크 ON
        bookmarkCount: nil,        // FIXME(BE-API): 응답 포함 시 전달
        onBookmarkTap: { bookmarkTapped(item.spotId) }
    )
}
.padding(.horizontal, 16)
.padding(.bottom, 24)
```

### 8.5 저장된 스팟 — 빈 상태 (ArchiveEmptyView)

```
  [큰 제목] 마음에 드는 스팟을
            발견하셨나요?

  [소제목]  나만의 출사 리스트를 채워보세요.
            저장된 스팟은 여기서 언제든 확인할 수 있어요.

  [버튼]  ────────────────────────────
         │         스팟 둘러보기       │   ← 주황색 rounded, 전체 너비
         ────────────────────────────
```
- 버튼 탭 → `onNavigateToExplore()` 콜백 호출 → `ContentView`에서 `selectedTab = .explore`

### 8.6 비로그인 상태 (ArchiveSignedOutView)

**선례**: `MyProfileSignedOutContent` 구조 그대로 복사 후 문구만 교체 (`Feature/MyProfile/Components/MyProfileSignedOutContent.swift`).

```
  [로고]  PICKFLOW   ← 좌측 상단, Image("pickflow_wordmark"), w140 h32

  [중앙]  보관함 기능을 사용하려면
          로그인이 필요해요
          (.heading(.large), center)

          마음에 드는 스팟을 저장하고, 언제든
          꺼내 볼 수 있는 나만의 리스트를 만들어 보세요.
          (.body(.medium()), gray40, center)

  [카카오 버튼]  KakaoLoginButton(action: onKakaoLoginTap)
  [애플 버튼]    AppleLoginButton(action: onAppleLoginTap)
```
- `KakaoLoginButton`, `AppleLoginButton`: `Feature/Auth/Components/` 기존 컴포넌트 재사용
- 탭 → `viewModel.signInWithKakao/Apple()` → 성공 시 `onAppear()` 재호출로 자동 데이터 로드
- `isLoginLoading` 동안 버튼 비활성화 (`MyProfileViewModel` 동일 패턴)

---

## 9. 디자인 시스템 추가 — **에셋 입력 매트릭스 (Gate 4)**

> **이 두 매트릭스가 모두 채워진 다음에야 §10 Phase A를 시작한다.** 미채움 상태로 Phase A 진입 금지.

### 9.1 컬러 매트릭스

| 토큰명 | Figma node | hex (Light) | hex (Dark) | 용도 |
|---|---|---|---|---|
| `gray95` (기존) | — | `#F2F2F2` | `#0D0D0D` | 전체 배경 |
| `gray0` (기존) | — | 기존 | 기존 | 텍스트/아이콘 |
| `gray50` (기존) | — | 기존 | 기존 | 비활성 탭 텍스트 |
| `gray70` (기존) | — | 기존 | 기존 | 헤더 fallback 배경 |
| `sunsetOrange` (기존) | — | `#FF6D2A` 추정 | 동일 | "스팟 둘러보기" 버튼 배경 |
| 카카오 노랑 | FIXME(Figma) | `#FEE500` | `#FEE500` | 카카오 로그인 버튼 (KakaoLoginButton 기존 사용 여부 확인) |
| 탭 underline | FIXME(Figma) | white(`#FFFFFF`) 추정 | white | 활성 탭 하단 밑줄 |

추가 후 `tuist generate` 시 `UIAsset.Colors.*`에 자동 추가됨.

### 9.2 아이콘/이미지 매트릭스

| 에셋명 | Figma node | export 포맷 | 사이즈 (1x/2x/3x) | 용도 |
|---|---|---|---|---|
| `icBookmarkFilled` (기존) | — | — | — | 셀 북마크 ON |
| `icBookmarkBorder` (기존) | — | — | — | 셀 북마크 OFF (낙관적 해제 중) |
| 카카오로고 (기존) | — | — | — | `KakaoLoginButton` 내부 |
| 애플로고 (기존) | — | — | — | `AppleLoginButton` 내부 |
| `···` 아이콘 | FIXME(Figma 873:19709) | — | — | 우측 상단 버튼 (placeholder) |

`Pickflow/Resources/Assets.xcassets/<name>.imageset/`에 등록.

### 9.3 타이포 매핑 (사용한 토큰만)

| 사용처 | 토큰 | 폴백 |
|---|---|---|
| 헤더 "나의 보관함" 대형 타이틀 | FIXME(Figma 측정 — `.display` 또는 custom size 추정) | `system(size:34, weight:.bold)` |
| NavigationBar "나의 보관함" | FIXME | `.headline` |
| 탭 텍스트 | FIXME(Figma 측정) | `.pretendard(.body(.medium()))` |
| 빈 상태 제목 "마음에 드는 스팟을…" | FIXME | `.pretendard(.title(.bold))` |
| 빈 상태 소제목 | FIXME | `.pretendard(.body(.medium()))` |
| "스팟 둘러보기" 버튼 | FIXME | `.pretendard(.body(.medium(.bold)))` |
| 비로그인 제목 | FIXME | `.pretendard(.title(.bold))` |
| 비로그인 소제목 | FIXME | `.pretendard(.body(.medium()))` |

> 매트릭스 채움 자가 점검:
> - [ ] §9.1, §9.2가 비어 있지 않다
> - [ ] 각 행이 실제 Figma 노드를 가리키고 hex/사이즈가 명시되어 있다
> - [ ] 누락된 토큰이 `<!-- FIXME -->`가 아니라 실제 값으로 채워졌다

위 3개 모두 통과해야 Phase A 진입.

---

## 10. TDD A→B→C 오케스트레이션 (Gate 1)

> **A → B → C는 직렬이다. 단계 건너뛰기·병렬화·역순 모두 금지.**
> 각 단계의 진입/작업/종료 디테일은 리프 문서에서 봄. 이 섹션은 **순서와 게이트만** 명시한다.

```
§9 에셋 매트릭스 (Gate 4)
        ↓
Phase A — ViewModel TDD (Gate 1A)
  · 진입: §3, §6, §9 모두 확정
  · 작업:
    - onAppear → 토큰 없음 → authState = .signedOut
    - onAppear → 토큰 있음 → fetchArchive → .loaded / .empty / .failed
    - handleSignedIn → fetchArchive → .loaded / .empty
    - tabChanged → selectedTab 변경 (나만의 스팟 탭은 no-op)
    - loadNextPageIfNeeded → hasNext 시 page+1 append
    - bookmarkTapped → 낙관적 제거 + 실패 복원 + toast
  · 종료: ArchiveViewModel 테스트 100% green, 뷰 파일 0개
  · 가이드: docs/phases/phase-a-viewmodel-tdd.md ← Phase A 들어갈 때 읽기
        ↓
Phase B — ui-test-cases.md (Gate 1B + Gate 2)
  · 진입: Phase A 종료 조건 통과
  · 작업: docs/KAN-53/ui-test-cases.md 8컬럼 표 작성
  · 케이스:
    - authState: signedOut
    - spotLoad: loading / loaded(N=1,짝수,홀수) / empty / failed
    - 탭: savedSpots / mySpots
    - 긴 이름 truncate, thumbnailUrl nil placeholder, distanceKm nil 숨김
    - 북마크 해제 직후 (item 제거된 상태)
  · 종료: TODO 0개, 행마다 스냅샷 파일명 결정
  · 가이드: docs/phases/phase-b-ui-cases.md ← Phase B 들어갈 때 읽기
        ↓
Phase C — Snapshot + UI (Gate 1C + Gate 3)
  · 진입: Phase B 종료 조건 통과
  · 작업: swift-snapshot-testing 케이스 RED → SwiftUI 뷰 → GREEN
  · 종료: 매트릭스 전 케이스 green, Figma 비교 루프 1회
  · 가이드: docs/phases/phase-c-snapshot.md ← Phase C 들어갈 때 읽기
```

> 각 Phase에 **들어갈 때** 해당 리프 문서를 read한다. 미리 다 읽어두지 않는다 — 단계 격리가 게이트의 본체다.

---

## 11. UI 검증 루프 (Figma 노드별 비교, Phase C 마무리)

| 컴포넌트 | Figma node-id | 확인 항목 |
|---|---|---|
| 전체 화면 (스팟 있음) | 873:19709 하위 FIXME | 헤더 이미지, 탭 바, 그리드 레이아웃 |
| 전체 화면 (빈 상태) | 873:19709 하위 FIXME | 제목/소제목/버튼 배치, 배경 |
| 전체 화면 (비로그인) | 873:19709 하위 FIXME | PICKFLOW 로고, 안내문, 버튼 스타일 |
| 스크롤 후 sticky 탭 | 873:19709 하위 FIXME | 헤더 축소, 탭 고정 상태 |
| 셀 | KAN-52 `SpotListCell` 동일 | 썸네일/이름/무드/거리/북마크 |

각 노드 조회: `mcp__claude_ai_Figma__get_design_context` / `get_screenshot` (fileKey `LyduUVMjsQi0qyUsENriR5`).

---

## 12. 디버그 진입점

```swift
// ContentView.swift — saved 탭 (구현 후)
case .saved:
    NavigationStack(path: $savedPath) {
        ArchiveView(
            viewModel: ArchiveViewModel(
                archiveService: getArchiveService(),
                bookmarkService: getBookmarkService(),
                tokenStore: getTokenStore()
            ),
            onNavigateToExplore: { selectedTab = .explore }
        )
    }
```

`ArchiveMockService`에 다양한 상태(empty/loaded/failed) preset 제공. PR 머지 전 `AppContainer`의 Mock 등록을 실 서비스로 교체 (FIXME 주석으로 명시).

---

## 13. 논의 포인트

`docs/KAN-53/archive-discussion.md` — 후속 합의 필요 항목.

- **(a) API 응답 스펙**: `GET /v1/users/me/archive`가 `SpotListPage`와 동일 구조인지, `distanceKm`·`bookmarkCount` 포함 여부 BE 확인 필요.
- **(b) `ArchiveEndpoint` 케이스명**: `getImage` → `fetchArchive(page:)` 리네임. `uploadImage`는 다른 티켓.
- **(c) 헤더 이미지 소스**: 최근 저장 스팟의 `thumbnailUrl`인지, 별도 API 응답 필드인지 BE 확인.
- **(d) 비로그인 플로우**: `MyProfileView`와 동일 방식으로 **확정** — 탭 내 인라인 로그인 UI. `authService.currentAuthState()` → `.signedOut` → `ArchiveSignedOutView`. `AppRootView` 수정 불필요.
- **(e) 나만의 스팟 탭 placeholder**: 탭 탭 시 "준비 중" toast만 뜨게 할지, body만 빈 View로 둘지.

---

## 14. 마감 체크리스트

**게이트 통과**
- [ ] Gate 1 (TDD A→B→C 직렬): 단계 순서 위반 없음
- [ ] Gate 2 (`ui-test-cases.md`): TODO 0개, 8컬럼 채움
- [ ] Gate 3 (swift-snapshot-testing): 매트릭스 전 케이스 green, `__Snapshots__/` PR 첨부, record 블라인드 덮어쓰기 0건
- [ ] Gate 4 (에셋 매트릭스): §9.1·§9.2 채움 후에 Phase A 시작했음

**일반**
- [ ] `SWIFT_STRICT_CONCURRENCY: complete` 빌드 경고/에러 0
- [ ] §11 Figma 비교 루프 1회 이상
- [ ] §12 진입 경로 시뮬레이터 동작 확인
- [ ] `SavedHomeView` 제거 (`DummyViews/`에서 삭제)
- [ ] `ContentView` `.saved` 탭 `onNavigateToExplore` 콜백 연결 확인
- [ ] BE-API FIXME 항목 PR 본문에 명시 + BE 티켓 링크
- [ ] §13(d) 비로그인 플로우 확정 (MyProfileView 동일 패턴 — 추가 합의 불필요)
- [ ] `docs/KAN-53/archive-discussion.md` 작성

---

## 15. 작업 순서 요약

```
0. §13(a)(b)(c)(d) 합의 → §9 에셋 매트릭스 채움 (Gate 4)
        ↓
1. docs/phases/phase-a-viewmodel-tdd.md 읽기 → Phase A 수행 (Gate 1A)
        ↓
2. docs/phases/phase-b-ui-cases.md 읽기 → Phase B 수행 (Gate 1B + 2)
        ↓
3. docs/phases/phase-c-snapshot.md 읽기 → Phase C 수행 (Gate 1C + 3) → §11 Figma 루프
        ↓
4. §12 디버그 검증 → §13 discussion 작성 → §14 통과 → PR
```
