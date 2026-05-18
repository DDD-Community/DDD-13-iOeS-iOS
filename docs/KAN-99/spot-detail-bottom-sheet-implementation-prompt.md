# [KAN-99] 스팟 상세 바텀시트 — 4-B 패턴 통합 구현 프롬프트

> **이 프롬프트의 사용법**: `screen-tdd-prompt` 스킬 산출물.
>
> **방법론은 여기 없다.** TDD 단계별 디테일은 단계 진입 시 리프 문서를 읽는다:
> - Phase A: `docs/phases/phase-a-viewmodel-tdd.md`
> - Phase B: `docs/phases/phase-b-ui-cases.md`
> - Phase C: `docs/phases/phase-c-snapshot.md`
>
> 본 문서는 **이 작업에만 해당하는 사실**(멘탈모델·스코프·정책·에셋·컴포넌트 매핑)을 담는다.

---

## 0. 작업 컨텍스트 (선결 정보)

**브랜치**: `feature/KAN-99` (이미 develop에서 분기/체크아웃됨)
**티켓**: https://dddios1.atlassian.net/browse/KAN-99
**Sheet phase Figma**: `https://www.figma.com/design/LyduUVMjsQi0qyUsENriR5/?node-id=908:18498`

**프로젝트 가정 (재탐색 불필요)**:
- SwiftUI + MVVM, Tuist 매니페스트(`Project.swift`)
- 외부 의존성: Alamofire, Swinject, KakaoSDK*, nMapsMap, FirebaseMessaging
- DI: `AppContainer.shared.registerDependencies()` → `getXxxService()` MainActor 헬퍼
- 디자인 시스템: `Resources/DesignSystem/Colors.xcassets` → `UIAsset.Colors.*` 자동 생성, `Common/DesignSystem/Fonts/PickflowTypography.swift`의 `.pretendard(...)` 토큰
- 테스트 타겟 `PickflowTests` 존재. 신규 테스트는 거기에 추가
- `SWIFT_STRICT_CONCURRENCY: complete` — 모든 신규 타입 `Sendable`/`@MainActor` 명시
- 선례: KAN-51(`Feature/SpotDetail/*`), 패턴 레퍼런스 `DDD-13-iOeS-iOS-KAN99-SampleApp/PickflowTransitionLab/Sources/Section2_UIKitNarrow/*`

**기 구현 자산 / 현재 상태**:
- `Feature/SpotDetail/BottomSheetContainer/` (UIKit 인프라)
  - `SpotBottomSheetShellViewController.swift` — generic `<Content: View>` host. **현재 phase를 모름**
  - `SpotPresentationController.swift` — phase별 frame/cornerRadius/grab handle 보간
  - `SpotPanGestureCoordinator.swift` — cooperate-with-scroll 제스처
  - `SpotTransitioningDelegate.swift`
  - `SpotBottomSheetPresenter.swift` — `.spotBottomSheet(isPresented:content:)` modifier
- `SpotDetailView.swift` — 풀 상세 뷰. **DetailChrome slot에 그대로 들어감**
- `SpotDetailViewModel.swift` — phase/detent 필드 **없음** (이번 작업에서 확장)

---

## 1. 멘탈모델 (4-B 패턴 — 단일 진실 소스)

> 이 섹션이 본 작업의 핵심. 이전 회차에서 멘탈모델이 두 번 바뀌었으니 **여기가 최종**임을 명시.

```
UIKit shell (SpotBottomSheetShellViewController)
  └── UIHostingController hosts → SpotShellRootView (SwiftUI, 신규)
                                    │
                                    └── switch viewModel.presentationPhase {
                                          case .sheetMedium:
                                              SheetChromeView {
                                                  SpotDetailSheetContentView(viewModel:)
                                              }
                                          case .sheetLarge, .fullCover:
                                              SpotDetailView(viewModel:)     ← 기존 뷰 그대로 (자체 nav 보유)
                                        }
```

핵심 통찰 — **phase 3개지만 SwiftUI 콘텐츠는 2개**:
| Phase | SwiftUI 콘텐츠 | 전환 비용 |
|---|---|---|
| `.sheetMedium` | `SheetChromeView { SpotDetailSheetContentView }` | medium ↔ large = **콘텐츠 swap** (cross-fade 필요) |
| `.sheetLarge` | `SpotDetailView` | large ↔ fullCover = **같은 뷰 frame 보간만** (cross-fade 불필요) |
| `.fullCover` | `SpotDetailView` (동일 인스턴스) | |

핵심 규칙:
- **phase 보유처**: `SpotDetailViewModel.presentationPhase` (단일 진실 소스)
- **phase 변경 주체**: UIKit 인프라(`SpotPresentationController` / pan coordinator)가 phase 결정 후 VM에 전파
- **SwiftUI 분기 위치**: `SpotShellRootView` 한 곳에서만. 자식 뷰는 phase를 모름
- **콘텐츠 swap 애니메이션**: medium ↔ large 사이는 SwiftUI `.transition(.opacity)` + `.animation(.easeInOut(duration: 0.2), value: viewModel.presentationPhase)` (사용자 합의). large/fullCover 사이는 SwiftUI 뷰 동일이라 별도 처리 불필요. 추후 시각적으로 어색하면 ZStack opacity 교차로 격상 검토
- **fullCover chrome**: `SpotDetailView`가 이미 `SpotDetailNavBar`를 자체 보유 (SpotDetailView.swift:14). **DetailChromeView 불필요**
- **sheet chrome**: `SheetChromeView`만 신규 — grab handle pill (sheet 본문은 분리된 `SpotDetailSheetContentView`)

샘플앱(`Section2_UIKitNarrow`)의 4-B 패턴을 본 프로젝트로 이식. 단 `DetailChromeView`는 불필요, large는 별도 SwiftUI 뷰 아니라 fullCover와 동일한 SpotDetailView 재사용.

---

## 2. 스코프

**구현 범위**:
- `SpotDetailViewModel`에 `presentationPhase` 필드 + 전이 액션(`promoteToFullCover`, `demoteToSheet`, `updateDetent`) 추가
- 신규 SwiftUI 컴포넌트
  - `SpotShellRootView` — phase 분기 (sheetMedium → Sheet 콘텐츠, sheetLarge/fullCover → SpotDetailView)
  - `SheetChromeView` — grab handle pill 래퍼
  - `SpotDetailSheetContentView` — Figma 908:18498 기반 medium 전용 본문 (사진 + 액션버튼 + 주소 펼침 토글 포함)
- 인프라 hook 확장
  - `SpotBottomSheetPresenter` — viewModel + gesture 콜백 받는 형태로 확장 (샘플 `SpotPresenter` 참고)
  - `SpotPresentationController` — phase didSet 시 VM 동기화 콜백 노출
  - `SpotPanGestureCoordinator` — onBegan/onTranslation/onEnded 콜백을 presenter가 주입할 수 있는 형태로 (이미 가까운지 확인)
- 디버그 진입점에서 medium ↔ large ↔ fullCover 전환 동작 확인

**범위 밖**:
- `SpotPresentationController`의 frame/cornerRadius 보간 곡선 변경
- `SpotPanGestureCoordinator`의 제스처 정책(cooperate-with-scroll, threshold 값) 변경
- `SpotDetailView`(fullCover) 자체 시각 변경
- 신규 API/모델 호출
- 외부 앱 연동(naver maps 등)은 SpotDetailView 측에 이미 있고, sheet phase엔 진입 액션 없음

**확정된 결정 (이전 회차 합의)**:
- `DetailChromeView` 불필요 — `SpotDetailView`가 `SpotDetailNavBar`를 자체 보유 (코드 확인 완료, SpotDetailView.swift:14)
- `SpotPresentationPhase` enum 위치: `Feature/SpotDetail/BottomSheetContainer/SpotPresentationPhase.swift` (인프라가 phase 결정 주체이므로 인프라 디렉토리에 정의, VM은 import)

---

## 3. 핵심 정책 결정 (사용자 확정)

| # | 항목 | 결정 |
|---|---|---|
| 1 | 멘탈모델 | 4-B 패턴. `SpotShellRootView` 안에서 SwiftUI가 phase로 chrome 분기 |
| 2 | phase 보유 | `SpotDetailViewModel.presentationPhase` (single source of truth) |
| 3 | phase 전이 주체 | UIKit 인프라가 결정 → VM에 전파. SwiftUI는 읽기만 |
| 4 | 진입점 modifier | 기존 `.spotBottomSheet(isPresented:content:)`를 viewModel/콜백 받는 형태로 확장 |
| 5 | 제스처 정책 | cooperate-with-scroll 고정. `contentOffset.y <= 0`에서만 pan begin |
| 6 | dismiss 규칙 | `sheetMedium`에서만 dismiss 허용 (`dy > 140` 또는 `velocity > 1400`). large/fullCover는 한 단계씩만 |
| 7 | medium → fullCover 직행 | `projected < -160`에서 한 제스처로 점프 업 허용 |
| 8 | chrome 정책 | shell이 그리는 chrome 없음(grab handle은 SwiftUI SheetChromeView가 그림). 4-A의 "PresentationController가 nav bar 그림" 옵션은 **채택 안 함** |

---

## 4. API 매핑

해당 없음. sheet phase 표시는 `SpotDetailViewModel`의 기 로드된 state만 읽음.

---

## 5. 신규/수정 파일 목록

**신규**
```
Pickflow/Sources/Feature/SpotDetail/
  ├── SpotShellRootView.swift                  ← phase로 분기. .fullCover→SpotDetailView, default→SheetChromeView
  ├── SpotDetailSheetContentView.swift         ← Figma 908:18498 기반 sheet 본문 (medium/large 분기 내장)
  ├── BottomSheetContainer/
  │   └── SpotPresentationPhase.swift          ← enum 정의 (인프라 측)
  └── Components/
      └── SheetChromeView.swift                ← grab handle pill + sheet 액션바
```

**수정**
- `Feature/SpotDetail/SpotDetailViewModel.swift` — `presentationPhase` 필드 + 전이 액션
- `Feature/SpotDetail/BottomSheetContainer/SpotBottomSheetPresenter.swift` — viewModel/gesture 콜백 받는 형태로 확장
- `Feature/SpotDetail/BottomSheetContainer/SpotPresentationController.swift` — phase didSet 시 VM 동기화 콜백 노출
- `Feature/SpotDetail/BottomSheetContainer/SpotPanGestureCoordinator.swift` — onBegan/onTranslation/onEnded 콜백 외부 주입 가능 형태(이미 그렇다면 변경 없음)
- 진입처 호출 부 — viewModel 주입한 새 modifier 호출로 변경

**동결**
- `SpotBottomSheetShellViewController.swift` — generic host 그대로 (Content 타입으로 `SpotShellRootView` 주입)
- `SpotTransitioningDelegate.swift`

---

## 6. 모델 정의 가이드

신규 모델 없음. 기존 `SpotDetail` 모델 그대로.

phase enum 정의 — `BottomSheetContainer/SpotPresentationPhase.swift`:

```swift
enum SpotPresentationPhase: Sendable, Equatable {
    case sheetMedium, sheetLarge, fullCover
}
```

ViewModel은 이 타입을 import해 `@Published presentationPhase` 보유.

---

## 7. ViewModel 시그니처 (확장)

```swift
@MainActor
final class SpotDetailViewModel: ObservableObject {
    // 기존 state/메서드 그대로

    @Published private(set) var presentationPhase: SpotPresentationPhase = .sheetMedium

    func promoteToFullCover()   // .sheetMedium/.sheetLarge → .fullCover
    func demoteToSheet()        // .fullCover → .sheetLarge
    func updateDetent(_ detent: SheetDetent) // medium/large 미세 변경
}
```

> Phase A 진입 직전, 위 시그니처를 KAN-99의 ViewModel에 합당한 형태로 확정한다. 액션 메서드명/시그니처는 합의 후 RED 작성.

DI 변경 없음.

---

## 8. 외부 앱 / 시스템 연동

해당 없음.

---

## 9. 화면별 정밀 사양

**sheet 본문 — phase별 콘텐츠 (사용자 확정)**:

- **`.sheetMedium`** — Figma 908:18498 기준. `SpotDetailSheetContentView` 단독 콘텐츠:
  1. Grab handle (`SheetChromeView`가 제공)
  2. Heading 영역 (908:18513): "잠원 한강공원" + "윤슬 · 북마크 34" + "2.5km · 서울시 강동구 ↑"
  3. 화살표 탭 → 주소 펼침 박스 (908:18540, 도로명/지번 복사) 노출. 토글은 **View 로컬 `@State isAddressExpanded`**
  4. 사진 영역 (908:18532, 높이 350)
  5. 액션 버튼 row (926:19479, "길 안내 받기" / "저장됨")

- **`.sheetLarge`** — `SpotDetailView` 그대로
- **`.fullCover`** — `SpotDetailView` 그대로 (large와 동일 SwiftUI 뷰. 컨테이너 frame만 다름)

> 즉 `SpotDetailSheetContentView`는 phase prop을 받지 않는다. medium 전용이라 phase가 자명. SwiftUI 분기는 `SpotShellRootView` 한 곳에서만.

**컨테이너 거동 사양** (참고용 — 변경 금지):
- Phase: `enum Phase { sheetMedium, sheetLarge, fullCover }` (인프라 내부)
- phase 변경 시 보간: `presentedView.frame`, `cornerRadius` (20 → 0), `grab handle alpha`
- 손가락 추적(.changed) → 정착(.ended) 스프링

---

## 10. 디자인 시스템 추가 — **에셋 입력 매트릭스 (Gate 4)**

> **이 매트릭스가 채워진 다음에야 §11 Phase A를 시작한다.** 미채움 상태로 Phase A 진입 금지.
>
> **추출 경로**: 현재 세션에 `mcp__claude_ai_Figma__*` 도구가 등록되어 있지 않아 Claude가 직접 추출 불가. 다음 중 택1:
> - (A) 사용자가 Claude Code Figma MCP 서버 활성화 후 Claude에게 재요청 → 자동 추출
> - (B) 사용자가 Figma dev mode에서 직접 hex/사이즈 export → 본 표 채움
> - (C) Figma 스크린샷·디자인 컨텍스트 텍스트 붙여넣기 → Claude가 표 변환

### 10.1 컬러 매트릭스

> 본 작업은 다크 모드 전용 디자인 (Figma file이 dark만 제공). Light 컬럼은 동일값 또는 추후 합의.

| 토큰명 | Figma node | Figma hex | 기존 토큰 매핑 | 용도 |
|---|---|---|---|---|
| `UIAsset.Colors.gray95` | 908:18510 (Bottom Sheet bg) | `#131416` | ✅ 기존 그대로 | Bottom Sheet 배경 (현재 SpotDetail도 동일 사용) |
| `UIAsset.Colors.gray90` | 908:18540 (주소 박스 bg), 908:18532 (사진 영역 bg) | `#1E2124` | ✅ 기존 그대로 | 카드/박스 surface |
| `UIAsset.Colors.gray80` | 908:18540 (주소 박스 stroke), 908:18501 (Bottom Nav stroke) | `#33363D` | ✅ 기존 그대로 | 1px 구분선 |
| `UIAsset.Colors.gray50` | 908:18520, 908:18524 (Ellipse dot separator) | `#6D7882` | ✅ 기존 그대로 | 점 구분자 |
| `UIAsset.Colors.gray30` | 908:18542, 908:18546 ("도로명"/"지번" label) | `#B1B8BE` | ✅ 기존 그대로 | 보조 라벨 |
| `UIAsset.Colors.gray10` | 908:18519 ("윤슬"), 908:18521 ("북마크 34"), 908:18523 ("2.5km") | `#E6E8EA` | ✅ 기존 그대로 | sheet 본문 텍스트 (primary on dark) |
| `UIAsset.Colors.gray0` | 908:18526 ("서울시 강동구"), 908:18543, 908:18547, 액션 버튼 텍스트, "저장됨" 버튼 bg | `#FFFFFF` | ✅ 기존 그대로 | 강조 텍스트 / 저장 버튼 bg |
| `UIAsset.Colors.sunsetOrange` | 908:18544, 908:18548 ("복사"), 926:19480 ("길 안내 받기" bg) | `#FA6133` | ✅ 기존 그대로 | 브랜드 액션 컬러 |
| `UIAsset.Colors.gray5` | 908:18516 ("잠원 한강공원") | `#F4F4F1` | ✅ 기존 `gray5 #F4F5F6`로 동일 취급 (1bit 차이, 사용자 합의) | 시트 헤딩 |
| **로컬 확장** `Color(hex: 0xD9D9D9)` | 908:18511 내부 pill | `#D9D9D9` | 🚫 디자인 시스템 토큰으로 승격 X. `SheetChromeView.swift` 내부 `fileprivate extension Color` 로만 정의 | grab handle pill |

**로컬 컬러 처리 (Phase A 진입 시 같이 작업)**:
- `SheetChromeView.swift` 하단에 `private extension Color { static let grabHandle = Color(red: 0xD9/255, green: 0xD9/255, blue: 0xD9/255) }` (또는 동등) 추가
- `Colors.xcassets`에 `gray15.colorset` **생성하지 않음** — 1곳에서만 쓰이는 색을 디자인 시스템에 올리지 않는다 (사용자 합의)

### 10.2 아이콘/이미지 매트릭스

| 에셋명 | Figma node | componentId | export 포맷 | 렌더 사이즈 | 용도 |
|---|---|---|---|---|---|
| `ic_arrow_up` | 908:18527 | 561:12221 | SVG | 20×20 | 주소 펼침/접힘 토글 (sheetMedium의 "서울시 강동구" 옆) |
| `ic_near_me` | I926:19480;926:19384 | 186:1765 | SVG | 20×20 | "길 안내 받기" 버튼 아이콘 |
| `ic_bookmark` | I926:19481;926:19388 | 184:721 | SVG | 20×20 | "저장됨" 버튼 아이콘 (filled) |
| `ic_bookmark_border` | (참고) | 184:724 | SVG | 20×20 | "저장 안 됨" 상태 (Figma 노드엔 없지만 토글 동작 위해 필요할 수 있음) |

> 위 아이콘 중 본 프로젝트 `Assets.xcassets/`에 이미 존재하는 것은 그대로 사용. 없는 것만 신규 import.
> 확인: `find Pickflow/Resources/Assets.xcassets -name "ic_arrow_up*" -o -name "ic_near_me*" -o -name "ic_bookmark*"` 로 사전 점검.

### 10.3 타이포 매핑

| 사용처 | Figma textStyle | 사양 | `PickflowTypography` 매핑 |
|---|---|---|---|
| "잠원 한강공원" (sheet 헤딩) | `Heading/large` | Pretendard SemiBold 24, lh 120% | `.pretendard(.heading(.large))` (없으면 추가) |
| "윤슬", "북마크 34", "서울시 강동구" | `Body/medium` | Pretendard Regular 15, lh 140% | `.pretendard(.body(.medium(.regular)))` |
| "2.5km" | `Body/medium-bold (199:3273)` | Pretendard SemiBold 15, lh 140% | `.pretendard(.body(.medium(.bold)))` |
| "도로명"/"지번" label | `Body/small` | Pretendard Regular 13, lh 140% | `.pretendard(.body(.small(.regular)))` |
| "강동대로 51길 28 1층", "성내동 446-6" | `Body/small` | 동일 | 동일 |
| "복사" (강조) | `Body/small-bold (199:3271)` | Pretendard SemiBold 13, lh 130% | `.pretendard(.body(.small(.bold)))` |
| "길 안내 받기", "저장됨" (액션 버튼) | `Body/large-bold` | Pretendard SemiBold 17, lh 140% | `.pretendard(.body(.large(.bold)))` |

> 위 매핑은 KAN-51 선례 기준 추정으로 1차 확정 (사용자 합의). Phase C 진입 시점에 `Common/DesignSystem/Fonts/PickflowTypography.swift`를 한 번 열어 실제 enum 케이스와 어긋나는 부분만 미세 조정.

> 자가 점검:
> - [x] §10.1, §10.2가 비어 있지 않다
> - [x] 각 행이 실제 Figma 노드를 가리키고 hex/사이즈가 명시되어 있다
> - [x] grab handle pill 색·사이즈·코너 명시되어 있다 (SheetChromeView 직접 의존)
> - [x] grab handle 색은 `SheetChromeView.swift` 내 fileprivate `Color` extension으로만 사용 (디자인 시스템 토큰 승격 X)

---

## 11. TDD A→B→C 오케스트레이션 (Gate 1)

> **A → B → C는 직렬이다. 단계 건너뛰기·병렬화·역순 모두 금지.**

```
§10 에셋 매트릭스 (Gate 4)
        ↓
Phase A — ViewModel TDD (Gate 1A)
  · 대상: SpotDetailViewModel의 phase 필드 + 전이 액션(promoteToFullCover/demoteToSheet/updateDetent)
  · 진입: §10 채움 완료, §7 시그니처 사용자 확정
  · 작업: 각 전이별 RED → GREEN, SwiftUI 뷰 0줄
    - initial state .sheetMedium
    - promoteToFullCover() 호출 시 .fullCover 전이
    - demoteToSheet() 호출 시 .sheetLarge 전이
    - 잘못된 전이(fullCover에서 promote 재호출 등)의 정책 — 합의 후 테스트
  · 종료: VM 테스트 100% green, SwiftUI 뷰 파일 0개 신규
  · 가이드: docs/phases/phase-a-viewmodel-tdd.md
        ↓
Phase B — ui-test-cases.md (Gate 1B + Gate 2)
  · 진입: Phase A 종료 조건 통과
  · 작업: docs/KAN-99/ui-test-cases.md 8컬럼 표 작성
    스냅샷 대상:
      - SheetChromeView (단독, grab handle pill만)
      - SpotDetailSheetContentView (medium frame 고정 — 주소 접힘/펼침 변형, 사진 로딩/실패 변형, 액션 버튼 isBookmarked 변형)
      - SpotShellRootView phase=.sheetMedium (전체 합성 검증)
      - phase=.sheetLarge / .fullCover는 SpotDetailView 기존 스냅샷에 의존 (이번에 신규 작성 불필요)
  · 종료: TODO 0개, 행마다 스냅샷 파일명 결정
  · 가이드: docs/phases/phase-b-ui-cases.md
        ↓
Phase C — Snapshot + UI (Gate 1C + Gate 3)
  · 진입: Phase B 종료 조건 통과
  · 작업: swift-snapshot-testing 케이스 RED → SwiftUI 뷰 → GREEN
  · 종료: 매트릭스 전 케이스 green, §12 Figma 비교 루프 1회
  · 가이드: docs/phases/phase-c-snapshot.md
        ↓
Phase D (인프라 합성, Phase C 종료 후) — 비TDD
  · SpotBottomSheetPresenter 확장 + PresentationController에 phase 콜백 hook
  · 시뮬레이터에서 실제 제스처 동작 검증 (§14 체크리스트)
```

> 각 Phase에 **들어갈 때** 해당 리프 문서를 read. 미리 다 읽어두지 않는다.

---

## 12. UI 검증 루프 (Figma 노드별 비교, Phase C 마무리)

| 컴포넌트 | Figma node-id | 확인 항목 |
|---|---|---|
| 시트 전체 (Bottom Sheet 컨테이너) | 908:18510 | 배경 #131416, borderRadius 20px 20px 0 0, padding 0px 20px 60px, gap 24px, boxShadow `bar`, 너비 390 |
| Grab handle pill | 908:18511 | pill 45×3, 색 #D9D9D9, 상하 padding 8px (총 영역 350×19) |
| Heading row (잠원 한강공원) | 908:18515 | Heading/large 24/SemiBold, color #F4F4F1 |
| Sub-info row (윤슬·북마크 34) | 908:18518 | gap 6, dot separator 3×3 #6D7882, Body/medium |
| Distance + address chevron row | 908:18522 | "2.5km" Body/medium-bold, dot, "서울시 강동구" Body/medium #FFFFFF + ic_arrow_up 20×20 |
| 사진 영역 (large 추가) | 908:18532 | 너비 fill, 높이 350, borderRadius 8, bg #1E2124, 이미지 fill cover |
| 주소 펼침 박스 | 908:18540 | column gap 6, padding 12, borderRadius 8, bg #1E2124, stroke 1px #33363D, 절대 위치 (x:20, y:128) |
| 도로명/지번 row | 908:18541, 908:18545 | row gap 4, "label"(gray30) + "값"(gray0) + "복사"(sunsetOrange) |
| 액션 버튼 row | 926:19479 | row gap 12, fill horizontal |
| "길 안내 받기" 버튼 | 926:19480 | bg sunsetOrange, borderRadius 8, height 52, icon+text Body/large-bold #FFFFFF |
| "저장됨" 버튼 | 926:19481 | bg #FFFFFF, borderRadius 8, height 52, icon+text Body/large-bold #33363D |

각 노드 조회: `mcp__figma__get_figma_data` / `mcp__figma__download_figma_images` (fileKey `LyduUVMjsQi0qyUsENriR5`).


---

## 13. 디버그 진입점

```swift
@State private var isSheetPresented = false
@StateObject private var viewModel: SpotDetailViewModel = /* DI resolved with debug mock */

Button("스팟 상세 시트 열기") { isSheetPresented = true }
    .spotBottomSheet(
        isPresented: $isSheetPresented,
        viewModel: viewModel
    ) {
        SpotShellRootView(viewModel: viewModel)
    }
```

> `gesturePolicy`는 `SpotPanGestureCoordinator` 내부에 cooperate-with-scroll로 동결되어 있어 modifier 인자로 노출하지 않는다. 실제 적용 예시: `Pickflow/Sources/App/CustomTabBarView/DummyViews/ExploreHomeView.swift`.

---

## 14. 논의 포인트 MD

`docs/KAN-99/spot-detail-bottom-sheet-discussion.md` — 후속 합의 필요 항목.

**해결됨 (이전 회차 → 본 문서에 반영)**:
- ~~DetailChromeView 신규 필요 여부~~ → 불필요. SpotDetailView 자체 nav 보유
- ~~SpotPresentationPhase enum 위치~~ → `BottomSheetContainer/SpotPresentationPhase.swift`
- ~~medium ↔ large 콘텐츠 차이~~ → §9에 명시 (medium: 윤슬 + 북마크 + 2.5km 주소 + 화살표/펼침. large: 그 외 추가 섹션)
- ~~"잘못된 전이 호출 정책"~~ → 폐기. phase 변경 주체가 UIKit 단일이므로 잘못된 호출이 발생할 경로가 사실상 없음. 만약 향후 외부에서 phase를 직접 수정하려는 시도가 생기면 그때 합의
- ~~"Phase D 회귀 보호 수단"~~ → 폐기. §15 마감 체크리스트의 시뮬레이터 수동 검증 6항목으로 갈음. 추가 자동화(Xcode UI test) 필요 시 별도 티켓

**남은 항목**:
- (없음 — Phase A 진입 가능)

---

## 15. 마감 체크리스트

**게이트 통과**
- [ ] Gate 1 (TDD A→B→C 직렬): 단계 순서 위반 없음. Phase D는 Phase C 종료 이후
- [ ] Gate 2 (`ui-test-cases.md`): TODO 0개, 8컬럼 채움
- [ ] Gate 3 (swift-snapshot-testing): 매트릭스 전 케이스 green, `__Snapshots__/` PR 첨부, record 블라인드 덮어쓰기 0건
- [ ] Gate 4 (에셋 매트릭스): §10.1·§10.2 채움 후에 Phase A 시작했음

**일반**
- [ ] `SWIFT_STRICT_CONCURRENCY: complete` 빌드 경고/에러 0
- [ ] §12 Figma 비교 루프 1회 이상
- [ ] §13 디버그 진입점에서 시뮬레이터 동작 확인
  - [ ] medium에서 강하게 위 스와이프 → 한 번에 fullCover 도달 + VM phase = .fullCover
  - [ ] fullCover 스크롤 내릴 때 시트 안 끌려옴
  - [ ] 스크롤 최상단에서 아래로 끌면 sheetLarge → sheetMedium + VM phase 동기
  - [ ] medium에서 살짝 아래로는 dismiss 안 됨
  - [ ] .changed 동안 손가락 따라 실시간 보간
  - [ ] `SpotShellRootView`의 chrome 분기가 phase 전환과 시각적으로 부드럽게 일치
- [ ] 인프라 동결 부분 diff 확인: `SpotBottomSheetShellViewController.swift`, `SpotTransitioningDelegate.swift`, `SpotPanGestureCoordinator.swift` 내부 정책 값 무변화
- [ ] `docs/KAN-99/spot-detail-bottom-sheet-discussion.md` 작성

---

## 16. 작업 순서 요약

```
0. §0~§9 합의 → §10 에셋 매트릭스 채움 (Gate 4)
        ↓
1. docs/phases/phase-a-viewmodel-tdd.md 읽기 → Phase A 수행
   (presentationPhase + 전이 액션 RED→GREEN)
        ↓
2. docs/phases/phase-b-ui-cases.md 읽기 → Phase B 수행
   (ShellRootView/Chrome/SheetContent 스냅샷 매트릭스 작성)
        ↓
3. docs/phases/phase-c-snapshot.md 읽기 → Phase C 수행
   (스냅샷 RED → 뷰 → GREEN) → §12 Figma 루프
        ↓
4. Phase D — 인프라 hook 합성
   (Presenter 확장 + PresentationController phase 콜백 + ShellRootView 주입)
        ↓
5. §13 디버그 검증 → §14 논의 포인트 → §15 통과 → PR
```

> 순서 위반 시 PR 본문에 명시. 단계 건너뛰기는 회귀 비용으로 직결.
