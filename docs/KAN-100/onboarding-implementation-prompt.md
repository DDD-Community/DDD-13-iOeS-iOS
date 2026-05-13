# [KAN-100] 온보딩 화면 구현 통합 프롬프트

> **이 프롬프트의 사용법**: `screen-tdd-prompt` 스킬이 이 템플릿을 복제·치환해서 `docs/KAN-100/onboarding-implementation-prompt.md`로 저장한 결과물이다.
>
> **방법론은 여기 없다.** TDD 단계별 디테일은 단계 진입 시 리프 문서를 읽는다:
> - Phase A: `docs/phases/phase-a-viewmodel-tdd.md`
> - Phase B: `docs/phases/phase-b-ui-cases.md`
> - Phase C: `docs/phases/phase-c-snapshot.md`
>
> 본 문서는 **이 화면에만 해당하는 사실**(스코프, API, 정책, 에셋, 컴포넌트 매핑)을 담는다.

---

## 0. 작업 컨텍스트 (선결 정보)

**브랜치**: `feature/KAN-100` (이미 develop에서 분기/체크아웃됨, 워크트리: `DDD-13-iOeS-iOS-KAN100/`)
**티켓**: https://dddios1.atlassian.net/browse/KAN-100
**전체 화면 Figma**: https://www.figma.com/design/LyduUVMjsQi0qyUsENriR5/DDD-design?node-id=870-32594
- `FIGMA_FILE_KEY`: `LyduUVMjsQi0qyUsENriR5`
- `FIGMA_ROOT_NODE_ID`: `870:32594` (URL의 `870-32594`를 `:`로 변환)

**Figma 프레임명 (4페이지)**:
- `Onboarding-01-DiscoverSpot`: 지도/리스트 탐색 강조 (오렌지 톤)
- `Onboarding-02-ShareSpot`: 내 스팟 기록/공유 강조 (오렌지 톤)
- `Onboarding-03-Tag-Sunset`: 노을 태그 소개 (오렌지 톤)
- `Onboarding-04-Tag-Water`: 윤슬 태그 소개 (블루 톤)

> **진실 소스**: Figma 노드(dev mode 컬러/타이포/스페이싱)가 1차. 입력 시안 PNG 4장은 보조(스냅샷 비교 백업용).

**프로젝트 가정 (재탐색 불필요)**:
- SwiftUI + MVVM, Tuist 매니페스트(`Project.swift`)
- 외부 의존성: Alamofire, Swinject, KakaoSDK*, nMapsMap, FirebaseMessaging
- DI: `AppContainer.shared.registerDependencies()` → `getXxxService()` MainActor 헬퍼
- 디자인 시스템: `Resources/DesignSystem/Colors.xcassets` → `UIAsset.Colors.*` 자동 생성, `Common/DesignSystem/Fonts/PickflowTypography.swift`의 `.pretendard(...)` 토큰
- 테스트 타겟 `PickflowTests` 존재 (KAN-51부터). 신규 테스트는 거기에 추가
- `SWIFT_STRICT_CONCURRENCY: complete` — 모든 신규 타입 `Sendable`/`@MainActor` 명시
- 선례: KAN-51(`Feature/SpotDetail/*`)

> **메모**: §9.1 컬러는 Figma dev mode hex가 확정값. §9.2 일러스트는 이미 등록되어 있다(PDF 벡터, 아래 §9.2 참조). §11 검증 루프는 Figma 노드 ↔ 시뮬레이터 캡처 비교 (PNG 시안은 보조).

---

## 1. 스코프

**구현 범위**:
- 4페이지 정적 온보딩 컨텐츠 (DiscoverSpot / ShareSpot / Tag-Sunset / Tag-Water)
- 스와이프 페이지 전환 (좌/우 제스처 + 인디케이터 동기화)
- 페이지 인디케이터 (4개 도트, 현재 페이지 강조)
- "시작하기" CTA — **모든 페이지에서 노출, 어느 페이지에서 눌러도 완료 처리**
- 온보딩 완료 시 `UserDefaults`에 `hasSeenOnboarding = true` 기록
- 앱 launch 시 `hasSeenOnboarding` 플래그로 온보딩 표시 분기 (진입점 1곳 수정)
- Assets.xcassets에 4개 일러스트 + 신규 컬러 토큰 등록

**범위 밖**:
- 스킵(건너뛰기) 버튼 — Figma 시안에 없음, 별도 합의 필요
- 설정 화면의 "온보딩 다시 보기" 진입점 — 별도 티켓
- 햅틱/추가 트랜지션 애니메이션 — 기본 SwiftUI 페이지 전환만
- 다국어 지원 — 한국어 하드코딩, i18n은 별도 티켓
- A/B 테스트, 분석 이벤트 — 별도 합의

---

## 2. 핵심 정책 결정 (사용자 확정)

| # | 항목 | 결정 |
|---|---|---|
| 1 | 표시 정책 | 최초 1회만 노출. `UserDefaults.standard.bool(forKey: "hasSeenOnboarding")`로 분기 |
| 2 | "시작하기" 버튼 노출 | 모든 페이지에 노출. 어느 페이지에서 눌러도 완료 처리 |
| 3 | 페이지 전환 | 스와이프 + 인디케이터 탭(선택). 좌우 스와이프 양방향 가능 |
| 4 | 스킵 버튼 | **포함하지 않음** (시안에 없음) |
| 5 | 완료 플래그 키 | `UserDefaults`의 `"hasSeenOnboarding"` (Bool) — 명세 변경 시 마이그레이션 필요 |
| 6 | 진입점 분기 위치 | 앱 root(`PickflowApp.swift` 또는 RootView)에서 플래그 검사 후 `OnboardingView` vs 메인 분기 |
| 7 | 마지막 페이지 처리 | 인디케이터·CTA 동일. "시작하기"가 onboarding 종료 액션 |

---

## 3. API 매핑

| UI 동작 | Endpoint | 비고 |
|---|---|---|
| (없음) | — | 온보딩은 순수 UI + UserDefaults. 네트워크 호출 없음 |

> Phase A 테스트는 API 모킹 없이 `UserDefaults`(또는 추상화된 `OnboardingCompletionStore`) 페이크로 검증한다.

---

## 4. 신규/수정 파일 목록

**신규**
```
Pickflow/Sources/Feature/Onboarding/
├── OnboardingView.swift                    # 페이지 컨테이너 (TabView paging)
├── OnboardingPageView.swift                # 단일 페이지 (일러스트 + 타이틀/서브 + CTA)
├── OnboardingPage.swift                    # 페이지 메타데이터 모델 (Sendable)
├── OnboardingViewModel.swift               # 상태/액션 (currentIndex, finish 등)
└── OnboardingCompletionStore.swift         # UserDefaults 추상화 (테스트용)

Pickflow/Resources/Assets.xcassets/Onboarding/   # ✅ 이미 등록됨
├── onboarding_0.imageset/                  # Page 0 일러스트 (DiscoverSpot)
├── onboarding_1.imageset/                  # Page 1 일러스트 (ShareSpot)
├── onboarding_2.imageset/                  # Page 2 일러스트 (Tag-Sunset)
└── onboarding_3.imageset/                  # Page 3 일러스트 (Tag-Water)

PickflowTests/Feature/Onboarding/
├── OnboardingViewModelTests.swift          # Phase A 테스트
└── OnboardingSnapshotTests.swift           # Phase C 테스트
```

**수정**
- `Pickflow/Sources/App/PickflowApp.swift` (또는 RootView 분기 지점) — `hasSeenOnboarding` 플래그로 OnboardingView 표시
- `Pickflow/Sources/App/AppContainer.swift` — `OnboardingCompletionStore` 등록
- `Pickflow/Resources/DesignSystem/Colors.xcassets/` — §9.1에서 신규 컬러 토큰 추가 시
- `Project.swift` — 신규 리소스/타겟 추가 필요 시 (보통 자동)

---

## 5. 모델 정의 가이드

```swift
import Foundation

struct OnboardingPage: Identifiable, Hashable, Sendable {
    enum AccentTheme: Sendable { case orange, blue }

    let id: Int                  // 0..3
    let imageName: String        // "onboarding_0".."onboarding_3" — Assets.xcassets/Onboarding/
    let title: String            // "흩어진 포토스팟,\n이제 한 번에 찾을 수 있어요"
    let subtitle: String         // "지도 뷰와 리스트 뷰를 통해\n원하는 방식으로 스팟을 쉽게 탐색해요."
    let titleHighlight: String?  // 색상 강조 부분 (예: "한 번에", "노을이 가장 아름다운 순간")
    let theme: AccentTheme       // 페이지 4(윤슬)만 .blue, 나머지 .orange
}

protocol OnboardingCompletionStore: Sendable {
    func hasSeenOnboarding() -> Bool
    func markOnboardingSeen()
}

struct UserDefaultsOnboardingCompletionStore: OnboardingCompletionStore {
    private let key = "hasSeenOnboarding"
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    func hasSeenOnboarding() -> Bool { defaults.bool(forKey: key) }
    func markOnboardingSeen() { defaults.set(true, forKey: key) }
}
```

JSONDecoder는 `convertFromSnakeCase` 전역 적용 → 모델엔 CodingKeys 박지 않는다. (이 화면은 디코딩 없음)

---

## 6. ViewModel 시그니처

```swift
@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var pages: [OnboardingPage]
    @Published var currentIndex: Int = 0
    @Published private(set) var isFinished: Bool = false

    private let completionStore: OnboardingCompletionStore

    init(
        pages: [OnboardingPage] = OnboardingPage.defaultPages,
        completionStore: OnboardingCompletionStore
    ) {
        self.pages = pages
        self.completionStore = completionStore
    }

    var isOnFirstPage: Bool { currentIndex == 0 }
    var isOnLastPage: Bool { currentIndex == pages.count - 1 }

    func goToNextPage() { /* clamp 0..<pages.count */ }
    func goToPreviousPage() { /* clamp 0..<pages.count */ }
    func setPage(_ index: Int) { /* clamp + assign */ }
    func finishOnboarding() {
        completionStore.markOnboardingSeen()
        isFinished = true
    }
}
```

DI: `AppContainer.registerDependencies()`에 `OnboardingCompletionStore` 등록.
- `container.register(OnboardingCompletionStore.self) { _ in UserDefaultsOnboardingCompletionStore() }.inObjectScope(.container)`
- MainActor 헬퍼: `func getOnboardingCompletionStore() -> OnboardingCompletionStore`

---

## 7. 외부 앱 / 시스템 연동

해당 없음 (이 화면은 외부 앱/딥링크/공유 sheet 사용 안 함).

---

## 8. 화면별 정밀 사양

### 8.1 공통 레이아웃
- 세이프 에어리어 최상단부터 상태바 노출. 상단에 `PICKFLOW` 워드마크는 일러스트 영역 좌상단(좌측 정렬)
- 상단 절반: 페이지 고유 일러스트 영역 (대략 화면 높이 55%, Figma 프레임 기준 확정)
- 하단 절반: 다크 배경 패널 (상단 코너 라운드 여부 Figma에서 확정) — 타이틀 + 서브타이틀 + 인디케이터 + CTA
- **하단 패널 내부 텍스트·인디케이터·CTA는 모두 가로 중앙 정렬** (시안 확인)
- 타이틀은 2줄, 서브타이틀도 2줄 (개행은 §8.4의 `\n` 그대로)
- 인디케이터: 4개. 활성은 가로로 길쭉한 pill (오렌지/블루 액센트), 비활성은 작은 원형 점 (다크 그레이)
- CTA: 풀 와이드, 좌우 패딩·높이·corner radius는 Figma에서 확정. 라벨 "시작하기", 배경은 오렌지 액센트 (Page 0~2·Page 3 동일)

### 8.2 페이지별 일러스트 컨텐츠
| Index | Asset | 비주얼 요약 | 액센트 |
|---|---|---|---|
| 0 | `onboarding_0` | 지도 스크린샷 + 지도/리스트 토글, 핀 마커들 | orange |
| 1 | `onboarding_1` | 폰 mockup + 스팟 상세 카드 + "나만의 스팟이 등록되었어요!" chat bubble | orange |
| 2 | `onboarding_2` | "노을" chip (filled) + 3장 일몰 이미지 가로 배치 | orange |
| 3 | `onboarding_3` | "윤슬" chip (outlined-blue) + 3장 윤슬 이미지 가로 배치 | blue |

### 8.3 타이틀 강조 색상 (페이지 인덱스 0..3)

| Page | 강조 범위 (정확) | 색상 |
|---|---|---|
| 0 | `한 번에 찾을 수 있어요` | 오렌지 (`onboardingAccentOrange`) |
| 1 | `나만의 스팟을` | 오렌지 |
| 2 | `노을이 가장 아름다운 순간` | 오렌지 |
| 3 | `윤슬이 가장 반짝이는 순간` | 블루 (`onboardingAccentBlue`) |

> 강조 외 나머지는 흰색(`#FFFFFF`). 강조 부분은 같은 폰트 토큰을 쓰고 색만 다르게 적용. Page 0의 "이제 "는 흰색 유지.

### 8.4 텍스트 (정확한 카피, 정렬: 가로 중앙)
| Page | Title (2줄) | Subtitle (2줄) |
|---|---|---|
| 0 | `흩어진 포토스팟,\n이제 한 번에 찾을 수 있어요` | `지도 뷰와 리스트 뷰를 통해\n원하는 방식으로 스팟을 쉽게 탐색해요.` |
| 1 | `나만의 스팟을\n기록하고 공유해보세요` | `내가 촬영한 스팟을 지도에 남기고\n확인할 수 있어요.` |
| 2 | `하루의 끝자락에서,\n노을이 가장 아름다운 순간` | `노을 태그로,\n그 순간을 담은 스팟을 찾아보세요.` |
| 3 | `물가에 빛이 닿을 때,\n윤슬이 가장 반짝이는 순간` | `윤슬 태그로,\n그 순간을 담은 스팟을 찾아보세요.` |

> 강조 색 적용은 §8.3 표 기준으로 `AttributedString` 또는 `Text(...) + foregroundStyle(...)`로 부분 처리.

---

## 9. 디자인 시스템 추가 — **에셋 입력 매트릭스 (Gate 4)**

> **§9.1·§9.2가 채워진 다음에야 §10 Phase A를 시작한다.** §9.3은 `PickflowTypography` 토큰 확인 후 확정.

### 9.1 컬러 매트릭스 — **Figma dev mode hex가 확정값**

> Figma node에서 `mcp__claude_ai_Figma__get_design_context`로 hex 추출. PNG 샘플링은 검증/백업용.
> Light/Dark 분리는 Figma에 모드가 있을 때만. 단일 모드면 양쪽 동일 hex.

| 토큰명 | Figma node-id | hex (Light) | hex (Dark) | 용도 |
|---|---|---|---|---|
| `onboardingBackgroundOrange` | <!-- TODO: Figma 조회 --> | <!-- TODO --> | <!-- TODO --> | Page 0~2 상단 일러스트 배경 |
| `onboardingBackgroundBlue` | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | Page 3 상단 일러스트 배경 |
| `onboardingPanelBackground` | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | 하단 다크 패널 |
| `onboardingAccentOrange` | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | CTA 배경, Page 0~2 타이틀 강조, 활성 인디케이터 |
| `onboardingAccentBlue` | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | Page 3 타이틀 강조, Page 3 chip 보더 |
| `onboardingTitle` | <!-- TODO --> | `#FFFFFF` | `#FFFFFF` | 타이틀 본문 색 |
| `onboardingSubtitle` | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | 서브타이틀 색 |
| `onboardingIndicatorInactive` | <!-- TODO --> | <!-- TODO --> | <!-- TODO --> | 비활성 인디케이터 도트 |

> 작업자 메모: Phase A 진입 전 1회 batch로 Figma MCP(`mcp__claude_ai_Figma__get_design_context`, fileKey=`LyduUVMjsQi0qyUsENriR5`, root=`870:32594`) 호출해 본 표를 채운다. 이미 존재하는 디자인 시스템 토큰(`UIAsset.Colors.*`)에 매핑되는 게 있으면 신규 토큰 대신 재사용.

추가 후 `tuist generate` 시 `UIAsset.Colors.*`에 자동 추가됨. 추가 위치: `Pickflow/Resources/DesignSystem/Colors.xcassets/`.

### 9.2 아이콘/이미지 매트릭스 — **✅ 이미 등록 완료**

| 에셋명 | 경로 | 포맷 | 옵션 | 용도 |
|---|---|---|---|---|
| `onboarding_0` | `Assets.xcassets/Onboarding/onboarding_0.imageset/onboarding_0.pdf` | PDF | preserves-vector-representation: true, universal | Page 0 일러스트 |
| `onboarding_1` | `Assets.xcassets/Onboarding/onboarding_1.imageset/onboarding_1.pdf` | PDF | preserves-vector-representation: true, universal | Page 1 일러스트 |
| `onboarding_2` | `Assets.xcassets/Onboarding/onboarding_2.imageset/onboarding_2.pdf` | PDF | preserves-vector-representation: true, universal | Page 2 일러스트 |
| `onboarding_3` | `Assets.xcassets/Onboarding/onboarding_3.imageset/onboarding_3.pdf` | PDF | preserves-vector-representation: true, universal | Page 3 일러스트 |

> 단일 PDF + 벡터 보존이므로 1x/2x/3x 분리 불필요. SwiftUI `Image("onboarding_0")`로 직접 참조.

### 9.3 타이포 매핑 — **Figma 타이포 + PickflowTypography 토큰 매칭**

> Figma dev mode에서 텍스트 노드의 font-size/weight/line-height를 확인하고, `Common/DesignSystem/Fonts/PickflowTypography.swift`에서 가장 가까운 토큰 선택. 매칭되는 토큰이 없으면 §13에 신규 토큰 추가 항목 등록.

| 사용처 | Figma 스펙 (확정 필요) | PickflowTypography 토큰 |
|---|---|---|
| 페이지 타이틀 | <!-- TODO: size/weight/lineHeight --> | <!-- TODO --> |
| 타이틀 강조 부분 | 동일 토큰 + foregroundColor | 동일 |
| 서브타이틀 | <!-- TODO --> | <!-- TODO --> |
| CTA 라벨 | <!-- TODO --> | <!-- TODO --> |
| 태그 chip (Page 2, 3) | <!-- TODO --> | <!-- TODO --> |

> 매트릭스 채움 자가 점검:
> - [ ] §9.1: 8개 행에 Figma node-id + hex 채움
> - [ ] §9.2: 4개 PDF 자산 등록 확인 (이미 완료 ✅)
> - [ ] §9.3: Figma 스펙 + PickflowTypography 토큰명으로 5개 행 확정

위 3개 모두 통과해야 Phase A 진입.

---

## 10. TDD A→B→C 오케스트레이션 (Gate 1)

> **A → B → C는 직렬이다. 단계 건너뛰기·병렬화·역순 모두 금지.**
> 각 단계의 진입/작업/종료 디테일은 리프 문서에서 봄. 이 섹션은 **순서와 게이트만** 명시한다.

```
§9 에셋 매트릭스 (Gate 4)
        ↓
Phase A — ViewModel TDD (Gate 1A)
  · 진입: §3, §6, §9 모두 확정 (이 화면은 §3 비어 있음 → OK)
  · 작업: 인터랙션별 RED → GREEN, SwiftUI 뷰 0줄
    - currentIndex 초기값/증감/감소/clamp
    - setPage 경계 처리
    - finishOnboarding → store.markOnboardingSeen 호출 + isFinished true
    - isOnFirstPage/isOnLastPage 계산
  · 종료: ViewModel 테스트 100% green, 뷰 파일 0개
  · 가이드: docs/phases/phase-a-viewmodel-tdd.md ← Phase A 들어갈 때 읽기
        ↓
Phase B — ui-test-cases.md (Gate 1B + Gate 2)
  · 진입: Phase A 종료 조건 통과
  · 작업: docs/KAN-100/ui-test-cases.md 8컬럼 표 작성
    - 페이지별 (4) + 인디케이터 상태별 (4) + 동적 케이스 (스와이프 후) 정도
  · 종료: TODO 0개, 행마다 스냅샷 파일명 결정
  · 가이드: docs/phases/phase-b-ui-cases.md ← Phase B 들어갈 때 읽기
        ↓
Phase C — Snapshot + UI (Gate 1C + Gate 3)
  · 진입: Phase B 종료 조건 통과
  · 작업: swift-snapshot-testing 케이스 RED → SwiftUI 뷰 → GREEN
  · 종료: 매트릭스 전 케이스 green, 시안 이미지 비교 루프 1회 (Figma 권한 없으므로 입력 PNG와 비교)
  · 가이드: docs/phases/phase-c-snapshot.md ← Phase C 들어갈 때 읽기
```

> 각 Phase에 **들어갈 때** 해당 리프 문서를 read한다. 미리 다 읽어두지 않는다 — 단계 격리가 게이트의 본체다.

---

## 11. UI 검증 루프 (Figma 노드별 비교, Phase C 마무리)

| 컴포넌트 | Figma node-id | Figma 프레임명 | 확인 항목 |
|---|---|---|---|
| Page 0 (전체) | <!-- TODO: Figma 조회 --> | `Onboarding-01-DiscoverSpot` | 배경색, 상태바, 일러스트 정렬, 하단 패널 |
| Page 1 (전체) | <!-- TODO --> | `Onboarding-02-ShareSpot` | 폰 mockup + chat bubble 비율, 하단 패널 |
| Page 2 (전체) | <!-- TODO --> | `Onboarding-03-Tag-Sunset` | 노을 chip + 3장 이미지 가로 정렬 |
| Page 3 (전체) | <!-- TODO --> | `Onboarding-04-Tag-Water` | 윤슬 chip + 3장 이미지, 다크블루 배경 |
| 상단 PICKFLOW 워드마크 | <!-- TODO --> | (공통 컴포넌트) | 폰트/위치/크기 |
| 하단 패널 (공통) | <!-- TODO --> | (공통 컴포넌트) | 타이틀/서브타이틀/인디케이터/CTA 정렬 |
| 페이지 인디케이터 | <!-- TODO --> | (공통 컴포넌트) | 활성 도트 pill 형태, 색상, 4개 |
| 시작하기 CTA | <!-- TODO --> | (공통 컴포넌트) | 풀와이드, 라벨, 탭 시 hasSeenOnboarding 기록 |

각 노드 조회: `mcp__claude_ai_Figma__get_design_context` / `get_screenshot` (fileKey `LyduUVMjsQi0qyUsENriR5`, root `870:32594`).
**보조 비교**: 입력 시안 PNG 4장과도 교차 비교(스냅샷 회귀 시 백업 진실 소스로 활용).

---

## 12. 디버그 진입점

```swift
@State private var isOnboardingPresented = false

Button("온보딩 열기") { isOnboardingPresented = true }
    .fullScreenCover(isPresented: $isOnboardingPresented) {
        OnboardingView(
            viewModel: OnboardingViewModel(
                completionStore: AppContainer.shared.getOnboardingCompletionStore()
            )
        )
    }
```

> 디버그 메뉴에 임시 토글 추가 — UserDefaults 플래그를 리셋해 다시 온보딩 진입 가능하게.

---

## 13. 논의 포인트 MD

`docs/KAN-100/onboarding-discussion.md` — 후속 합의 필요 항목.

- **§9.1 컬러 hex/node-id 확정**: Figma MCP(`get_design_context`, fileKey `LyduUVMjsQi0qyUsENriR5`, root `870:32594`)로 8행 채움. Phase A 진입 전 1회 batch.
- **§9.3 타이포 토큰**: Figma 텍스트 노드 스펙 + `PickflowTypography.swift` 토큰 매칭. 매칭 없는 케이스는 신규 토큰 추가. Phase A 진입 직전.
- **§11 컴포넌트별 node-id 확보**: 8개 행. Figma root 트리에서 child 추출.
- **스킵 버튼**: 시안엔 없음. (a) 그대로 미포함 (b) 우상단에 "건너뛰기" 추가 — 현재 (a)로 결정
- **마지막 페이지 CTA 라벨**: 시안은 "시작하기" 통일. (a) 모든 페이지 동일 (b) 마지막만 "시작하기", 그 외 "다음" — 시안 기준 (a) 채택
- **앱 진입 분기 위치**: (a) `PickflowApp.swift` body 분기 (b) RootView 내부 if/else — 기존 패턴 확인 필요
- **i18n**: 현재 한국어 하드코딩. Localizable.strings 적용 시점 — 별도 티켓
- **분석 이벤트**: 페이지뷰/완료 이벤트 발화 여부 — 별도 합의
- **(사이드픽스) `MockSpotService` 보정**: 본 PR이 `PickflowTests/Helpers/SpotDetailTestDoubles.swift`의 `MockSpotService`에 `registerSpot(draft:)` 스텁을 추가했음. develop에 이미 들어간 `SpotServiceProtocol.registerSpot` 변경에 mock 업데이트가 누락되어 PickflowTests 빌드가 깨져 있었던 결함. Phase A 테스트 실행을 위해 불가피하게 함께 수정. 별도 티켓 분리 검토 가능
- **(스킵된 게이트) §9.1·§9.3·§11**: 사용자 명시 결정으로 Phase A 진입 전 채움을 스킵. Phase C 진입 전(또는 Phase B 작성 직전)에 다시 채워야 스냅샷·UI 검증 의미가 살아남. 본 PR 머지 전 반드시 재방문

---

## 14. 마감 체크리스트

각 Phase 리프 문서에 단계별 종료 조건이 있다. 여기서는 **PR 머지 직전 한 번 더 확인할 게이트만** 모은다.

**게이트 통과**
- [x] Gate 1 (TDD A→B→C 직렬): 단계 순서 위반 없음 — A → B → C 순서대로 진행
- [x] Gate 2 (`ui-test-cases.md`): TODO 0개, 8컬럼 채움, 20행
- [x] Gate 3 (swift-snapshot-testing): 20/20 케이스 green, `__Snapshots__/` 디렉토리 PR 첨부 대상, record는 초기 시드 1회만
- [ ] Gate 4 (에셋 매트릭스): **§9.1·§9.3·§11 사용자 명시 스킵으로 빈 상태**. Phase C는 코드베이스 기존 토큰(`sunsetOrange`, `sunsetOrangeBg`, `themeReflection`, `surfaceModal`, `gray0/60/70`) + 블루 하드코딩으로 보완 진행. 추후 Figma dev mode 확정 시 batch 갱신 필요(§13)

**일반**
- [x] `SWIFT_STRICT_CONCURRENCY: complete` 빌드 경고/에러 0 (Onboarding 신규 코드)
- [x] §11 시각 비교 루프: Page 0/Page 3 베이스라인 PNG 직접 확인 → 시안과 일치
- [ ] 시뮬레이터에서 launch 플로우 직접 확인 (UserDefaults 리셋 후 첫 진입에 OnboardingView 노출 / 시작하기 탭 시 ContentView 전환) — **수동 확인 미수행**, 다음 단계
- [ ] UserDefaults 플래그 리셋·재진입 시 정상 동작 — 수동 확인 미수행
- [ ] `docs/KAN-100/onboarding-discussion.md` 작성 (옵션, §13 본문이 대체)

> 단계 내부 체크리스트(예: "Phase A 종료 조건")는 해당 리프 문서를 본다. 여기 중복으로 박지 않는다.

---

## 15. 작업 순서 요약

```
0. §0~§8 합의 → §9 에셋 매트릭스 채움 (Gate 4)
        ↓
1. docs/phases/phase-a-viewmodel-tdd.md 읽기 → Phase A 수행 (Gate 1A)
        ↓
2. docs/phases/phase-b-ui-cases.md 읽기 → Phase B 수행 (Gate 1B + 2)
        ↓
3. docs/phases/phase-c-snapshot.md 읽기 → Phase C 수행 (Gate 1C + 3) → §11 시안 비교 루프
        ↓
4. §12 디버그 검증 → §13 논의 포인트 → §14 통과 → PR
```

> 순서를 어겼다면 PR 본문에 어디서 거꾸로 갔는지 명시. 단계 건너뛰기는 회귀 비용으로 직결된다.
