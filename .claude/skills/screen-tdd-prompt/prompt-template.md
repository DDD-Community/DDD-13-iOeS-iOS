# [{{TICKET}}] {{SCREEN_NAME}} 화면 구현 통합 프롬프트

> **이 프롬프트의 사용법**: `screen-tdd-prompt` 스킬이 이 템플릿을 복제·치환해서 `docs/{{TICKET}}/{{SCREEN_SLUG}}-implementation-prompt.md`로 저장한다.
>
> **방법론은 여기 없다.** TDD 단계별 디테일은 단계 진입 시 리프 문서를 읽는다:
> - Phase A: `.claude/skills/screen-tdd-prompt/phases/phase-a-viewmodel-tdd.md`
> - Phase B: `.claude/skills/screen-tdd-prompt/phases/phase-b-ui-cases.md`
> - Phase C: `.claude/skills/screen-tdd-prompt/phases/phase-c-snapshot.md`
>
> 본 문서는 **이 화면에만 해당하는 사실**(스코프, API, 정책, 에셋, 컴포넌트 매핑)을 담는다.

---

## 0. 작업 컨텍스트 (선결 정보)

**브랜치**: `feature/{{TICKET}}` (이미 develop에서 분기/체크아웃됨)
**티켓**: {{JIRA_URL}}
**전체 화면 Figma**: `https://www.figma.com/design/{{FIGMA_FILE_KEY}}/?node-id={{FIGMA_ROOT_NODE_ID}}`

**프로젝트 가정 (재탐색 불필요)**:
- SwiftUI + MVVM, Tuist 매니페스트(`Project.swift`)
- 외부 의존성: Alamofire, Swinject, KakaoSDK*, nMapsMap, FirebaseMessaging
- DI: `AppContainer.shared.registerDependencies()` → `getXxxService()` MainActor 헬퍼
- 디자인 시스템: `Resources/DesignSystem/Colors.xcassets` → `UIAsset.Colors.*` 자동 생성, `Common/DesignSystem/Fonts/PickflowTypography.swift`의 `.pretendard(...)` 토큰
- 테스트 타겟 `PickflowTests` 존재 (KAN-51부터). 신규 테스트는 거기에 추가
- `SWIFT_STRICT_CONCURRENCY: complete` — 모든 신규 타입 `Sendable`/`@MainActor` 명시
- 선례: KAN-51(`Feature/SpotDetail/*`)

<!-- 프로젝트가 위 가정과 다르면 여기 추가 메모 -->

---

## 1. 스코프

**구현 범위**:
<!-- TODO -->

**범위 밖**:
<!-- TODO: 의도적으로 뺀 것 -->

---

## 2. 핵심 정책 결정 (사용자 확정)

| # | 항목 | 결정 |
|---|---|---|
<!-- TODO -->

---

## 3. API 매핑

| UI 동작 | Endpoint | 비고 |
|---|---|---|
<!-- TODO -->

---

## 4. 신규/수정 파일 목록

**신규**
```
<!-- TODO: 디렉토리 트리 -->
```

**수정**
<!-- TODO -->

---

## 5. 모델 정의 가이드

```swift
// TODO: Codable, Sendable 모델 + enum
```

JSONDecoder는 `convertFromSnakeCase` 전역 적용 → 모델엔 CodingKeys 박지 않는다.

---

## 6. ViewModel 시그니처

```swift
@MainActor
final class {{SCREEN_NAME_PASCAL}}ViewModel: ObservableObject {
    enum LoadState: Equatable { case idle, loading, loaded(/* TODO */), failed(String) }
    @Published private(set) var state: LoadState = .idle
    // TODO

    init(/* TODO: 서비스 + 테스트 가능성 위한 clock/uuid 등 */)

    // TODO: 액션 (async)
}
```

DI: `AppContainer.registerDependencies()`에 신규 서비스 등록.

---

## 7. 외부 앱 / 시스템 연동

<!-- TODO: URL scheme, LSApplicationQueriesSchemes, fallback. 없으면 섹션 삭제 가능 -->

---

## 8. 화면별 정밀 사양

<!-- TODO: 비표준 시각 컴포넌트만(예: 일몰 progress). 없으면 섹션 삭제 -->

---

## 9. 디자인 시스템 추가 — **에셋 입력 매트릭스 (Gate 4)**

> **이 두 매트릭스가 모두 채워진 다음에야 §10 Phase A를 시작한다.** 미채움 상태로 Phase A 진입 금지.

### 9.1 컬러 매트릭스

| 토큰명 | Figma node | hex (Light) | hex (Dark) | 용도 |
|---|---|---|---|---|
<!-- TODO -->

추가 후 `tuist generate` 시 `UIAsset.Colors.*`에 자동 추가됨.

### 9.2 아이콘/이미지 매트릭스

| 에셋명 | Figma node | export 포맷 | 사이즈 (1x/2x/3x) | 용도 |
|---|---|---|---|---|
<!-- TODO -->

`Pickflow/Resources/Assets.xcassets/<name>.imageset/`에 등록.

### 9.3 타이포 매핑 (사용한 토큰만)

| 사용처 | 토큰 | 폴백 |
|---|---|---|
<!-- TODO -->

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
  · 진입: §3, §6, §9 모두 확정
  · 작업: 인터랙션별 RED → GREEN, SwiftUI 뷰 0줄
  · 종료: ViewModel 테스트 100% green, 뷰 파일 0개
  · 가이드: phases/phase-a-viewmodel-tdd.md ← Phase A 들어갈 때 읽기
        ↓
Phase B — ui-test-cases.md (Gate 1B + Gate 2)
  · 진입: Phase A 종료 조건 통과
  · 작업: docs/{{TICKET}}/ui-test-cases.md 8컬럼 표 작성
  · 종료: TODO 0개, 행마다 스냅샷 파일명 결정
  · 가이드: phases/phase-b-ui-cases.md ← Phase B 들어갈 때 읽기
        ↓
Phase C — Snapshot + UI (Gate 1C + Gate 3)
  · 진입: Phase B 종료 조건 통과
  · 작업: swift-snapshot-testing 케이스 RED → SwiftUI 뷰 → GREEN
  · 종료: 매트릭스 전 케이스 green, Figma 비교 루프 1회
  · 가이드: phases/phase-c-snapshot.md ← Phase C 들어갈 때 읽기
```

> 각 Phase에 **들어갈 때** 해당 리프 문서를 read한다. 미리 다 읽어두지 않는다 — 단계 격리가 게이트의 본체다.

---

## 11. UI 검증 루프 (Figma 노드별 비교, Phase C 마무리)

| 컴포넌트 | Figma node-id | 확인 항목 |
|---|---|---|
<!-- TODO -->

각 노드 조회: `mcp__claude_ai_Figma__get_design_context` / `get_screenshot` (fileKey `{{FIGMA_FILE_KEY}}`).

---

## 12. 디버그 진입점

```swift
@State private var is{{SCREEN_NAME_PASCAL}}Presented = false

Button("{{SCREEN_NAME}} 열기") { is{{SCREEN_NAME_PASCAL}}Presented = true }
    .fullScreenCover(isPresented: $is{{SCREEN_NAME_PASCAL}}Presented) {
        {{SCREEN_NAME_PASCAL}}View(viewModel: /* DI resolved */)
    }
```

---

## 13. 논의 포인트 MD

`docs/{{TICKET}}/{{SCREEN_SLUG}}-discussion.md` — 후속 합의 필요 항목.
<!-- TODO: (a)/(b)/(c) 옵션 -->

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
- [ ] §12 디버그 진입점에서 시뮬레이터 동작 확인
- [ ] 외부 앱 연동(있다면) 시뮬/실기기 검증
- [ ] `docs/{{TICKET}}/{{SCREEN_SLUG}}-discussion.md` 작성

> 단계 내부 체크리스트(예: "Phase A 종료 조건")는 해당 리프 문서를 본다. 여기 중복으로 박지 않는다.

---

## 15. 작업 순서 요약

```
0. §0~§8 합의 → §9 에셋 매트릭스 채움 (Gate 4)
        ↓
1. phase-a-viewmodel-tdd.md 읽기 → Phase A 수행 (Gate 1A)
        ↓
2. phase-b-ui-cases.md 읽기 → Phase B 수행 (Gate 1B + 2)
        ↓
3. phase-c-snapshot.md 읽기 → Phase C 수행 (Gate 1C + 3) → §11 Figma 루프
        ↓
4. §12 디버그 검증 → §13 논의 포인트 → §14 통과 → PR
```

> 순서를 어겼다면 PR 본문에 어디서 거꾸로 갔는지 명시. 단계 건너뛰기는 회귀 비용으로 직결된다.
