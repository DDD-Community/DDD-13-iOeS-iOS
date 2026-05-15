# [KAN-106] 온보딩 일러스트 리팩토링 구현 통합 프롬프트

> **이 프롬프트의 사용법**: `screen-tdd-prompt` 스킬이 템플릿을 복제·치환해서 저장한 문서. 신규 화면이 아니라 **기존 `OnboardingIllustration` 컴포넌트 리팩토링**이라 §3 API / §5 모델 / §6 ViewModel 시그니처 일부는 비어 있다(스코프 밖).
>
> **방법론은 여기 없다.** TDD 단계별 디테일은 단계 진입 시 리프 문서를 읽는다:
> - Phase A: `docs/phases/phase-a-viewmodel-tdd.md`
> - Phase B: `docs/phases/phase-b-ui-cases.md`
> - Phase C: `docs/phases/phase-c-snapshot.md`
>
> 본 문서는 **이 작업에만 해당하는 사실**(스코프, 정책, 에셋, 컴포넌트 매핑)을 담는다.

---

## 0. 작업 컨텍스트 (선결 정보)

**브랜치**: `feature/KAN-106` (develop에서 분기, base는 `feature/KAN-100`)
**티켓**: https://dddios1.atlassian.net/browse/KAN-106
**전체 화면 Figma**: `https://www.figma.com/design/LyduUVMjsQi0qyUsENriR5/DDD-design`
**페이지별 Figma 노드**:
- Step 0: node-id `870:32595`
- Step 1: node-id `870:32620`
- Step 2: node-id `870:32645`
- Step 3: node-id `870:32677`

**프로젝트 가정 (재탐색 불필요)**:
- SwiftUI + MVVM, Tuist 매니페스트
- DI: `AppContainer` (이 작업에선 변경 없음)
- 디자인 시스템: `Resources/DesignSystem/Colors.xcassets` → `UIAsset.Colors.*` 자동 생성
- 테스트 타겟: `PickflowTests`
- `SWIFT_STRICT_CONCURRENCY: complete`
- 기존 온보딩 구조: `Pickflow/Sources/Feature/Onboarding/` (Page/Palette/View/ViewModel + Components/)

**기존 통이미지 파일** (참고용, 일부 재사용):
- `Pickflow/Resources/Assets.xcassets/Onboarding/onboarding_0.imageset/onboarding_0_iphone.pdf`
- `Pickflow/Resources/Assets.xcassets/Onboarding/onboarding_1.imageset/onboarding_1_iphone.pdf`
- `Pickflow/Resources/Assets.xcassets/Onboarding/onboarding_{2,3}_pic_{0,1,2}.imageset/*.pdf`

---

## 1. 스코프

**구현 범위**:
- `OnboardingIllustration.swift` 전면 개편:
  - 배경: 기존 통이미지 대신 **그라데이션 + 전경 이미지** 합성
  - Step 0/1: 단일 아이폰 목업 이미지(`onboarding_0_iphone`, `onboarding_1_iphone`) 중앙 배치
  - Step 2/3: **3장의 1:1 정사각형 사진** 가로 자동 무한 캐러셀 (등속 가로 스크롤)
- `OnboardingPage` 모델에 **페이지별 그라데이션 정의** 추가 (시작/끝 color stop, angle)
- 전체 `OnboardingView` 레이아웃은 그대로 유지 (워드마크/타이틀/페이지 인디케이터/버튼 위치 변화 없음)

**범위 밖**:
- API 호출, 네트워크 모델 (없음)
- ViewModel 신규 액션 (캐러셀은 컴포넌트 내부 상태로 처리, `OnboardingViewModel` 수정 X 가정 — Phase A에서 재확인)
- 디자인 시스템 컬러 토큰 신규 등록 (그라데이션은 `OnboardingPage` 모델에 보유)
- 페이지 0/1의 통이미지 에셋 자체 교체 (기존 `iphone.pdf` 재사용)
- 캐러셀의 디바운스/제스처/사용자 인터랙션 (자동 스크롤 전용)

---

## 2. 핵심 정책 결정 (사용자 확정)

| # | 항목 | 결정 |
|---|---|---|
| 1 | Step 0/1 배경 | 동일 그라데이션 (Figma 0/1 노드 동일 색) |
| 2 | Step 2/3 배경 | **서로 다른** 그라데이션 (각 노드에서 hex 추출) |
| 3 | Step 2/3 전경 | 3장의 1:1 정사각형 사진 가로 자동 무한 캐러셀 |
| 4 | 캐러셀 방향 | 가로 (좌→우 또는 우→좌, Figma 디자인에 따라 Phase B에서 확정) |
| 5 | 캐러셀 속도 | 등속 자동 스크롤, 정확한 duration은 §9 에셋 매트릭스 채울 때 합의 |
| 6 | 캐러셀 인터랙션 | 없음. 사용자 제스처/일시정지 미지원 |
| 7 | 그라데이션 보유 위치 | `OnboardingPage` 모델 (각 페이지가 시작/끝 색 + 각도를 들고 있음) |
| 8 | 스냅샷 커버리지 | 페이지 0/1/2/3 정적 스냅샷만. 캐러셀 움직임은 수동 검증 |
| 9 | 레이아웃 변화 | 없음 — `OnboardingView` 외곽 구조 변동 금지 |

---

## 3. API 매핑

**해당 없음** — UI 전용 리팩토링.

---

## 4. 신규/수정 파일 목록

**수정**
- `Pickflow/Sources/Feature/Onboarding/OnboardingPage.swift` — `gradient: OnboardingPageGradient` 프로퍼티 추가, `defaultPages`에 페이지별 그라데이션 주입
- `Pickflow/Sources/Feature/Onboarding/Components/OnboardingIllustration.swift` — 그라데이션 배경 + 전경 분기(단일 이미지 vs 캐러셀)
- (필요 시) `OnboardingPalette.swift` — `gradient` 표현 헬퍼

**신규**
```
Pickflow/Sources/Feature/Onboarding/
  OnboardingPageGradient.swift        ← struct OnboardingPageGradient { stops, angle/start/end point }
  Components/
    OnboardingPhotoCarousel.swift     ← 3장 1:1 가로 무한 자동 스크롤
PickflowTests/Feature/Onboarding/
  OnboardingPageGradientTests.swift   ← Phase A 대상 (모델 단위)
  OnboardingIllustrationSnapshotTests.swift  ← Phase C 대상
```

**에셋 (이미 존재, 재확인만)**
- `Resources/Assets.xcassets/Onboarding/onboarding_{0,1}.imageset/`
- `Resources/Assets.xcassets/Onboarding/onboarding_{2,3}_pic_{0,1,2}.imageset/`

---

## 5. 모델 정의 가이드

```swift
struct OnboardingPageGradient: Hashable, Sendable {
    struct Stop: Hashable, Sendable {
        let color: ColorSpec   // 또는 hex 문자열 + 변환 유틸
        let location: CGFloat  // 0.0...1.0
    }
    let stops: [Stop]
    let startPoint: UnitPoint  // SwiftUI UnitPoint은 Sendable 아님 → 자체 enum/struct로 감쌀지 Phase A에서 결정
    let endPoint: UnitPoint
}
```

> Phase A 진입 시 `UnitPoint`의 Sendable 여부, `Color` vs hex string 표현 중 무엇을 모델에 둘지 결정. 모델 단위 테스트(`OnboardingPageGradientTests`)로 두 페이지(0=1, 2≠3) 동등성/비동등성 검증.

---

## 6. ViewModel 시그니처

**변경 없음** (가정). `OnboardingViewModel`은 페이지 인덱스만 관리하며, 캐러셀은 `OnboardingPhotoCarousel` 내부의 `TimelineView`/`Animation` 상태로 처리.

Phase A에서 `OnboardingViewModel`을 수정해야 한다는 결론이 나면 **여기로 돌아와 본 섹션을 채운 뒤** Phase A 재진입.

---

## 7. 외부 앱 / 시스템 연동

**해당 없음**.

---

## 8. 화면별 정밀 사양

### 8.1 캐러셀 (`OnboardingPhotoCarousel`)

- 입력: `images: [String]` (3장, 1:1 정사각형)
- **사이즈 정책 (확정)**: 가로 배치 3장 중 **가운데(index 1)는 원본 100%**, **좌우(index 0, 2)는 동일 비율 80%**
  - 즉 같은 1:1 비율이지만 좌우 사진은 가운데 사진의 0.8배 너비
  - 좌우 사진은 세로 중앙 정렬 (작아진 만큼 위아래 여백 확보)
- 레이아웃:
  - 캐러셀 가용 너비 안에서 가운데 사진 너비 W를 정하고, 좌우는 0.8W
  - 사진 사이 간격: Figma 합의값 (§9.2)
  - 무한 루프는 `HStack { ForEach(images × N) }`를 늘려 한 사이클 단위로 offset 등속 이동 후 리셋
- 애니메이션:
  - `.linear(duration: cycle).repeatForever(autoreverses: false)` 또는 `TimelineView(.animation)` + 시간 기반 offset 계산 중 Phase B에서 비교
- 결정성: 스냅샷은 `offset = 0` 기준 정적 캡처 → 캐러셀 init에 `isAnimating: Bool`(기본 true, 테스트는 false) 또는 `initialOffset:` 훅 주입

### 8.2 그라데이션 배경

- `LinearGradient(gradient: Gradient(stops: page.gradient.stops.map { ... }), startPoint: ..., endPoint: ...)`
- `OnboardingIllustration` 루트 `ZStack` 최하단에 배치, 그 위에 단일 이미지 또는 캐러셀

---

## 9. 디자인 시스템 추가 — **에셋 입력 매트릭스 (Gate 4)**

> **이 두 매트릭스가 모두 채워진 다음에야 §10 Phase A를 시작한다.**

### 9.1 컬러/그라데이션 매트릭스

| 페이지 | Figma node | 시작 색 hex | 끝 색 hex | start/end point | 비고 |
|---|---|---|---|---|---|
| 0 | 870:32595 | `#C96A35` (top) | `#E5926A` (bottom-right) | top → bottomTrailing | 1과 동일, 스크린샷 추정값 |
| 1 | 870:32620 | `#C96A35` | `#E5926A` | top → bottomTrailing | 0과 동일 |
| 2 | 870:32645 | `#0B0B10` (top) | `#1A1410` (bottom) | top → bottom | 매우 어둡고 약한 따뜻한 톤 (노을 페이지) |
| 3 | 870:32677 | `#0E1218` (top) | `#162536` (bottom) | top → bottom | 어둡고 약한 푸른 톤 (윤슬 페이지) |

> **주의**: 위 hex 값은 사용자 첨부 스크린샷에서 추정한 값으로 Figma dev mode 정확값과 다를 수 있다. Phase C Figma 비교 루프에서 디자이너 확인 또는 dev mode 실측으로 보정한다. 모델 TDD(Phase A)는 추정값으로 진행해도 무방 — 모델은 hex 자체에 의존하지 않음.

### 9.2 이미지 매트릭스

| 에셋명 | Figma node | 사용처 | 원본 사이즈 | 비고 |
|---|---|---|---|---|
| onboarding_0_iphone | 870:32595 내부 | Step 0 전경 | 기존 | 재사용 |
| onboarding_1_iphone | 870:32620 내부 | Step 1 전경 | 기존 | 재사용 |
| onboarding_2_pic_0/1/2 | 870:32645 내부 | Step 2 캐러셀 | 기존 1:1 | — |
| onboarding_3_pic_0/1/2 | 870:32677 내부 | Step 3 캐러셀 | 기존 1:1 | — |
| 캐러셀 가운데(100%) 사진 너비 | — | 캐러셀 레이아웃 | 화면폭의 약 **62%** (스크린샷 추정) | Figma 실측으로 보정 |
| 캐러셀 좌우(80%) 사진 너비 | — | 캐러셀 레이아웃 | 가운데 너비 × 0.8 (확정) | 비율 고정 |
| 캐러셀 간격 | — | 캐러셀 레이아웃 | **12pt** (추정) | — |
| 캐러셀 1사이클 duration | — | 애니메이션 | **16s** (등속, 사진 3장 1순환) | 추후 사용자 합의 시 조정 |

### 9.3 타이포 매핑

**해당 없음** — 텍스트 컴포넌트는 본 작업 스코프 밖.

> 매트릭스 채움 자가 점검:
> - [ ] §9.1 4개 행에 hex가 모두 채워졌다
> - [ ] §9.2 캐러셀 비율/간격/duration TODO가 모두 실제 값으로 치환됐다
> - [ ] 각 행이 실제 Figma 노드를 가리킨다

위 3개 모두 통과해야 Phase A 진입.

---

## 10. TDD A→B→C 오케스트레이션 (Gate 1)

> **A → B → C는 직렬이다.**

```
§9 에셋 매트릭스 (Gate 4)
        ↓
Phase A — 모델 TDD (Gate 1A)
  · 진입: §9 확정
  · 작업: OnboardingPageGradient 모델 + defaultPages 페이지별 그라데이션 단위 테스트 (0==1, 2≠3, 모든 페이지 stop 카운트 ≥ 2 등)
  · 종료: 모델 테스트 green, SwiftUI 뷰 코드 0줄
  · 가이드: docs/phases/phase-a-viewmodel-tdd.md ← Phase A 진입 시 read
        ↓
Phase B — ui-test-cases.md (Gate 1B + Gate 2)
  · 진입: Phase A 종료
  · 작업: docs/KAN-106/ui-test-cases.md 8컬럼 표 작성 (페이지 0/1/2/3 정적 케이스 4개 + 캐러셀 정적 0-offset 케이스)
  · 종료: TODO 0개
  · 가이드: docs/phases/phase-b-ui-cases.md
        ↓
Phase C — Snapshot + UI (Gate 1C + Gate 3)
  · 진입: Phase B 종료
  · 작업: OnboardingIllustrationSnapshotTests 4 케이스 RED → 그라데이션/캐러셀 뷰 구현 → GREEN
  · 종료: 4 케이스 green, Figma 비교 루프 1회
  · 가이드: docs/phases/phase-c-snapshot.md
```

---

## 11. UI 검증 루프

| 컴포넌트 | Figma node-id | 확인 항목 |
|---|---|---|
| Step 0 전체 | 870:32595 | 그라데이션 색·각도, 아이폰 이미지 위치/크기 |
| Step 1 전체 | 870:32620 | 0과 동일 그라데이션, 아이폰 이미지 |
| Step 2 전체 | 870:32645 | 그라데이션, 3장 캐러셀 첫 프레임 정렬 |
| Step 3 전체 | 870:32677 | 그라데이션(≠Step 2), 3장 캐러셀 첫 프레임 |
| 외곽 레이아웃 | (워드마크/타이틀/인디케이터/버튼) | KAN-100 대비 변동 없음 확인 |

fileKey: `LyduUVMjsQi0qyUsENriR5`

---

## 12. 디버그 진입점

기존 `OnboardingView` 디버그 진입점 재사용. 시뮬레이터에서 페이지 0→3 스와이프하며 그라데이션 전환과 캐러셀 자동 스크롤 육안 확인.

---

## 13. 논의 포인트 MD

`docs/KAN-106/onboarding-illustration-discussion.md` — 후속 합의 필요 항목:
- (a) 캐러셀 duration / 가운데 사진 너비 정확값 (사이즈 비율은 100/80/80으로 확정)
- (b) `UnitPoint` Sendable 우회 방식 (자체 struct vs `@unchecked Sendable`)
- (c) `OnboardingPalette` 폐기/재작성 — **자유롭게 수정 가능 (확정)**. 단, 수정 후 `xcodebuild ... build` 성공 필수. 그라데이션이 `OnboardingPage`로 이동하면서 역할이 줄어들면 폐기, 잔존 책임(예: 텍스트 강조색 등)이 있으면 그것만 남기고 리네임

---

## 14. 마감 체크리스트

**게이트 통과**
- [ ] Gate 1 (TDD A→B→C 직렬): 단계 순서 위반 없음
- [ ] Gate 2 (`ui-test-cases.md`): TODO 0개, 8컬럼 채움
- [ ] Gate 3 (swift-snapshot-testing): 4 페이지 정적 케이스 green, `__Snapshots__/` PR 첨부
- [ ] Gate 4 (에셋 매트릭스): §9.1·§9.2 채움 후 Phase A 시작

**일반**
- [ ] `SWIFT_STRICT_CONCURRENCY: complete` 빌드 경고/에러 0
- [ ] §11 Figma 비교 루프 1회 이상
- [ ] §12 시뮬레이터에서 캐러셀 자동 스크롤 + 페이지 전환 육안 검증
- [ ] `docs/KAN-106/onboarding-illustration-discussion.md` 작성
- [ ] `OnboardingView` 외곽 레이아웃 회귀 없음 (KAN-100 스냅샷과 동일)
- [ ] `OnboardingPalette` 수정/폐기 시 `xcodebuild ... build` 성공 (Common.xcconfig + Configs/ 복사된 워크트리에서 검증)

---

## 15. 작업 순서 요약

```
0. §0~§8 합의 (현재) → §9 에셋 매트릭스 채움 (Gate 4)
        ↓
1. docs/phases/phase-a-viewmodel-tdd.md read → OnboardingPageGradient 모델 TDD (Gate 1A)
        ↓
2. docs/phases/phase-b-ui-cases.md read → ui-test-cases.md 작성 (Gate 1B + 2)
        ↓
3. docs/phases/phase-c-snapshot.md read → 스냅샷 RED → 뷰 구현 → GREEN (Gate 1C + 3) → §11 Figma 루프
        ↓
4. §12 디버그 검증 → §13 논의 포인트 → §14 통과 → PR
```
