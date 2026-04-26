# [{{TICKET}}] {{SCREEN_NAME}} 화면 구현 통합 프롬프트

> **이 프롬프트의 사용법**: `screen-tdd-prompt` 스킬이 이 템플릿을 복제 후 `{{...}}` 자리를 채워서 `docs/{{TICKET}}/{{SCREEN_SLUG}}-implementation-prompt.md`로 저장한다. Claude는 그 한 장만 읽고 화면을 끝까지 구현할 수 있어야 한다.
>
> **불변 게이트(삭제 금지)**: 본 템플릿의 §0, §10, §11, §12, §15는 4개 강제 게이트(TDD A→B→C, ui-test-cases.md, swift-snapshot-testing, 에셋 매트릭스)를 박아둔 핵심부다. 어떤 화면이라도 이 5개 섹션을 빼지 않는다.

---

## 0. 작업 컨텍스트 (선결 정보)

**브랜치**: `feature/{{TICKET}}` (이미 develop에서 분기/체크아웃됨)
**티켓**: {{JIRA_URL}}
**전체 화면 Figma**: `https://www.figma.com/design/{{FIGMA_FILE_KEY}}/?node-id={{FIGMA_ROOT_NODE_ID}}`

**프로젝트 현재 상태 (재탐색 불필요)**:
- SwiftUI + MVVM, Tuist로 매니페스트 관리(`Project.swift`)
- 외부 의존성: Alamofire, Swinject, KakaoSDK*, nMapsMap, FirebaseMessaging
- 네트워킹: `Pickflow/Sources/Core/Network/{APIEndpoint, NetworkManager}.swift`
- DI: `AppContainer.shared.registerDependencies()`에 등록 → `getXxxService()` MainActor 헬퍼로 resolve
- 도메인 서비스: `Pickflow/Sources/Core/Services/*Service.swift`
- 기존 화면 패턴 참고: `Pickflow/Sources/Feature/Profile/{ProfileView, ProfileViewModel}.swift`, `Feature/SpotDetail/*` (KAN-51 선례)
- 디자인 시스템:
  - 컬러: `Pickflow/Resources/DesignSystem/Colors.xcassets` → `UIAsset.Colors.*` 자동 생성
  - 타이포: `Pickflow/Sources/Common/DesignSystem/Fonts/PickflowTypography.swift` — `.pretendard(.heading(.large))`
- 테스트 타겟: `PickflowTests` (KAN-51부터 존재). 신규 테스트는 거기에 추가
- `SWIFT_STRICT_CONCURRENCY: complete` 적용 중 → 모든 신규 타입 `Sendable`/`@MainActor` 명시
- Info.plist는 Tuist `Tuist/ProjectDescriptionHelpers/AppInfoPlist.swift`에서 생성

<!-- 프로젝트가 위 가정과 다르면 여기 추가 메모 -->

---

## 1. 스코프

**구현 범위**:
<!-- TODO: 화면이 다루는 인터랙션을 bullet으로 -->

**범위 밖**:
<!-- TODO: 이 PR에서 안 하는 것을 명시. "잘 안 만든 것"이 아니라 "의도적으로 뺀 것"임을 알 수 있게 -->

---

## 2. 핵심 정책 결정 (사용자 확정)

| # | 항목 | 결정 |
|---|---|---|
<!-- TODO: 일몰 윈도우/거리 단위/비로그인 처리/공유 텍스트 등 사용자 합의 결과를 한 줄씩 -->

---

## 3. API 매핑 ({{SCREEN_NAME}}이 사용하는 엔드포인트)

| UI 동작 | Endpoint | 비고 |
|---|---|---|
<!-- TODO: 동작 단위로 method/path/body/응답 처리 정책 -->

---

## 4. 신규/수정 파일 목록

**신규**
```
<!-- TODO: 디렉토리 트리 형태로 -->
```

**수정**
<!-- TODO: 기존 파일 변경 항목 -->

---

## 5. 모델 정의 가이드 (응답 매핑)

```swift
// TODO: Codable, Sendable 모델 + enum
```

JSONDecoder는 `convertFromSnakeCase` 전역 적용 → 모델엔 CodingKeys 박지 않는다.

---

## 6. ViewModel 상태/액션

```swift
@MainActor
final class {{SCREEN_NAME_PASCAL}}ViewModel: ObservableObject {
    enum LoadState: Equatable { case idle, loading, loaded(/* TODO */), failed(String) }
    @Published private(set) var state: LoadState = .idle
    // TODO: 화면별 추가 published 프로퍼티

    init(/* TODO: 서비스 프로토콜 + 테스트 가능성을 위한 clock/uuid/etc 주입 */)

    // TODO: 액션 메서드들 (async)
}
```

DI: `AppContainer.registerDependencies()`에 신규 서비스 등록 후 `getXxxService()` 헬퍼 추가.

---

## 7. 외부 앱 / 시스템 연동 사양

<!-- TODO: 네이버 지도/공유/딥링크/푸시 등. URL scheme, Info.plist `LSApplicationQueriesSchemes` 변경, fallback 정책 -->

---

## 8. 화면별 정밀 사양 (필요 시)

<!-- TODO: 일몰 progress 처럼 비표준 시각 컴포넌트가 있을 때만. 없으면 이 섹션 통째로 삭제 가능 -->

---

## 9. 디자인 시스템 추가 — **에셋 입력 매트릭스 (Gate 4)**

> **이 두 매트릭스가 모두 채워진 다음에야 §10 Phase A를 시작한다.** 매트릭스 미채움 상태로 Phase A 진입 금지.
>
> 출처: Figma dev mode에서 직접 hex 추출 / SVG export. `mcp__claude_ai_Figma__get_design_context`로 노드 단위 조회 가능.

### 9.1 컬러 매트릭스

| 토큰명 | Figma node | hex (Light) | hex (Dark) | 용도 |
|---|---|---|---|---|
<!-- TODO: 예) themeSunset / 686:18968 / #FF8A4C / — / 노을 칩 배경 -->

추가 후 `tuist generate` 시 `UIAsset.Colors.*`에 자동 추가됨 → `.foregroundStyle(.themeSunset)` 식 사용.

### 9.2 아이콘/이미지 매트릭스

| 에셋명 | Figma node | export 포맷 | 사이즈 (1x/2x/3x) | 용도 |
|---|---|---|---|---|
<!-- TODO: 예) icBookmarkBorder / 686:19045 / SVG / 24/48/72 / 북마크 토글 비활성 상태 -->

`Pickflow/Resources/Assets.xcassets/<name>.imageset/`에 등록. SVG는 `preserves-vector-representation: true` 권장.

### 9.3 타이포 매핑 (사용한 토큰만)

| 사용처 | 토큰 | 폴백 |
|---|---|---|
<!-- TODO: 예) 화면 타이틀 / .pretendard(.heading(.large)) / — -->

> 매트릭스 채움 상태 자가 점검 체크리스트:
> - [ ] §9.1, §9.2가 비어 있지 않다
> - [ ] 각 행이 실제 Figma 노드를 가리키고 hex/사이즈가 명시되어 있다
> - [ ] 채움 누락된 토큰은 `<!-- TODO -->`가 아니라 실제 값으로 채워졌다

위 3개 모두 통과해야 Phase A 진입 가능.

---

## 10. TDD A→B→C 3단계 (Gate 1 — **엄격, 직렬, 건너뛰기 금지**)

> A → B → C는 **직렬**이다. 각 단계의 종료 조건을 만족하기 전 다음 단계로 넘어가지 않는다. 동시 진행 / 단계 병합 금지.

### Phase A — ViewModel 단위 테스트 (Mock 기반)

**진입 조건**
- §9 에셋 매트릭스 두 표 모두 채워짐
- §3 API 매핑, §6 ViewModel 시그니처 합의됨

**작업**
1. `PickflowTests/Helpers/`에 필요한 Mock 서비스 추가 (예: `MockSpotService`, `MockBookmarkService` 패턴)
2. `PickflowTests/{{SCREEN_NAME_PASCAL}}ViewModelTests.swift` 생성
3. 인터랙션·상태 전이별로 테스트 작성 → RED 확인 → 최소 구현 → GREEN
4. **이 단계 동안 SwiftUI View 코드는 한 줄도 작성하지 않는다.** 컴포넌트 파일/Preview 파일도 생성 금지.

**작성할 테스트(예시 명명, 화면별 보강)**
<!-- TODO: 화면별 12개 안팎 -->
- `onAppear_정상응답_상태가loaded로전환된다`
- `onAppear_API실패_상태가failed로전환되고에러메시지가포함된다`
- 화면별 액션 테스트들…

**종료 조건**
- [ ] ViewModel 관련 테스트 100% green (`xcodebuild test ...`)
- [ ] `SWIFT_STRICT_CONCURRENCY: complete` 경고/에러 0
- [ ] SwiftUI 뷰 파일 0개 추가됨 (직렬성 자가 점검)

### Phase B — `docs/{{TICKET}}/ui-test-cases.md` 작성 (Gate 2)

**진입 조건**
- Phase A 종료 조건 모두 만족

**작업**
1. `docs/{{TICKET}}/ui-test-cases.md` (스킬이 빈 셸로 미리 만들어 둠) 본문 채우기
2. 컴포넌트 × 상태 × 테마 × 디바이스 × DynamicType × Light/Dark **매트릭스를 표로** 작성
3. 각 행에 `스냅샷 파일명`까지 미리 결정

**`ui-test-cases.md` 최소 컬럼**

| case id | 컴포넌트 | 상태/입력 조건 | 테마 | 언어 / DynamicType | Light/Dark | 디바이스 | 기대 시각 결과 | 스냅샷 파일명 |
|---|---|---|---|---|---|---|---|---|
<!-- TODO -->

**최소 커버리지**
- 각 컴포넌트의 핵심 상태(loading/loaded/empty/error) 모두
- 테마 분기가 있으면 분기당 1행 이상
- DynamicType은 `.large`(기본)와 `.accessibilityExtraLarge` 최소 2단계
- Light/Dark 둘 다

**종료 조건**
- [ ] `docs/{{TICKET}}/ui-test-cases.md`에 `<!-- TODO -->`가 남아 있지 않다
- [ ] 리뷰어가 표만 보고 어떤 스냅샷이 찍힐지 예측 가능
- [ ] 각 행에 `스냅샷 파일명`이 결정됨 (Phase C에서 그대로 사용)

> 종료 조건 미충족 상태로 Phase C에 진입하면 즉시 되돌릴 것.

### Phase C — Snapshot 테스트 + UI 구현 (Gate 3)

**진입 조건**
- Phase B 종료 조건 모두 만족

**작업**
1. `pointfreeco/swift-snapshot-testing`을 SPM 의존성으로 추가 (`Tuist/Package.swift` 또는 `Project.swift` 테스트 타겟). `tuist install && tuist generate`
2. `PickflowTests/{{SCREEN_NAME_PASCAL}}SnapshotTests.swift` 생성. ui-test-cases.md의 각 행을 그대로 케이스로 옮김
3. 모든 케이스 RED 확인 (스냅샷 미존재)
4. `Pickflow/Sources/Feature/{{SCREEN_NAME_PASCAL}}/` 하위에 SwiftUI 뷰 + 컴포넌트 작성
5. 스냅샷 record 모드로 1회 생성 → 시각 검증 → 본 모드로 GREEN
6. Figma 노드 비교 루프(§11) 1회 이상

**스냅샷 고정값(전 케이스 동일)**
- 디바이스: iPhone 15 시뮬레이터 (`.iPhone15`)
- 언어/지역: ko_KR
- DynamicType: 기본 `.large`. 접근성 케이스는 명시적으로 `.accessibilityExtraLarge`
- Appearance: Light / Dark 둘 다 (별도 케이스로)
- 시간: 결정성 위해 `clock` 주입값 고정 (예: 2025-04-26 19:00 KST)

**종료 조건**
- [ ] ui-test-cases.md의 모든 행에 대응 스냅샷 케이스가 있고 전부 green
- [ ] `__Snapshots__/` diff PR 본문에 첨부됨
- [ ] 의도적 변경분만 record로 갱신됨 (분석 없이 record 덮어쓰기 금지)
- [ ] §11 Figma 비교 루프 1회 통과

---

## 11. UI 검증 루프 (Figma 노드별 비교, Phase C 마무리 단계)

| 컴포넌트 | Figma node-id | 확인 항목 |
|---|---|---|
<!-- TODO: 컴포넌트 단위로 채울 것 -->

각 노드는 `mcp__claude_ai_Figma__get_design_context` 또는 `get_screenshot`으로 fileKey `{{FIGMA_FILE_KEY}}` + 해당 nodeId로 조회. 어긋남 발견 시 수정 → 재확인 → **이상 없을 때까지 루프**.

---

## 12. 디버그 진입점

```swift
// ContentView 또는 적절한 디버그 화면에 추가
@State private var is{{SCREEN_NAME_PASCAL}}Presented = false

Button("{{SCREEN_NAME}} 열기") { is{{SCREEN_NAME_PASCAL}}Presented = true }
    .fullScreenCover(isPresented: $is{{SCREEN_NAME_PASCAL}}Presented) {
        {{SCREEN_NAME_PASCAL}}View(viewModel: /* DI resolved */)
    }
```

실제 백엔드가 없으면 에러 상태로 보여도 OK. 필요 시 DEBUG 빌드용 mock fixture 등록 옵션.

---

## 13. 논의 포인트 MD

`docs/{{TICKET}}/{{SCREEN_SLUG}}-discussion.md`에 후속 합의 필요 항목을 적어둔다.
<!-- TODO: 항목별 (a)/(b)/(c) 옵션 형태 -->

---

## 14. 마감 체크리스트

**TDD A→B→C 3단계 게이트 (Gate 1)**
- [ ] Phase A: ViewModel 단위 테스트 모두 green (이 시점에 SwiftUI 뷰 코드 0줄)
- [ ] Phase B: `docs/{{TICKET}}/ui-test-cases.md` 작성 완료 (TODO 0개)
- [ ] Phase C: 매트릭스 전 케이스 스냅샷 green

**`ui-test-cases.md` 게이트 (Gate 2)**
- [ ] 표가 §10 Phase B에 정의된 8개 컬럼을 모두 가진다
- [ ] 각 행에 `스냅샷 파일명`이 명시되어 있다
- [ ] ui-test-cases.md 비어 있는 상태로 Phase C 진입한 적 없음

**swift-snapshot-testing 게이트 (Gate 3)**
- [ ] `pointfreeco/swift-snapshot-testing` SPM 추가 + `tuist generate` 반영
- [ ] 매트릭스 전 케이스 스냅샷 green
- [ ] `__Snapshots__/` diff PR 본문 첨부
- [ ] record 모드 갱신은 의도적 변경에만 사용 (분석 없이 덮어쓰기 0건)
- [ ] 시뮬레이터/언어/DynamicType/Appearance 고정값이 테스트 코드에 명시

**에셋 입력 매트릭스 게이트 (Gate 4)**
- [ ] §9.1 컬러 매트릭스 채움 (TODO 0개)
- [ ] §9.2 아이콘/이미지 매트릭스 채움 (TODO 0개)
- [ ] 매트릭스 채움 후에 Phase A 시작했음 (직렬성 자가 점검)

**일반**
- [ ] `SWIFT_STRICT_CONCURRENCY: complete` 빌드 경고/에러 0
- [ ] 컴포넌트별 Figma 노드 비교 루프 1회 이상 완료 (§11)
- [ ] 시뮬레이터에서 디버그 진입점 동작 확인
- [ ] 외부 앱 연동(있다면) 시뮬/실기기 검증
- [ ] `docs/{{TICKET}}/{{SCREEN_SLUG}}-discussion.md` 작성

---

## 15. 작업 순서 권고 (요약)

```
0. §0 컨텍스트/§1~§8 합의 → §9 에셋 매트릭스 채움 (Gate 4)
        ↓
1. Phase A — ViewModel TDD (mock, SwiftUI 뷰 0줄) (Gate 1A)
        ↓
2. Phase B — ui-test-cases.md 작성 (Gate 1B + Gate 2)
        ↓
3. Phase C — swift-snapshot-testing 도입 → 케이스 RED → SwiftUI 뷰 구현 → GREEN (Gate 1C + Gate 3)
        ↓
4. Figma 노드 비교 루프 (§11)
        ↓
5. 디버그 진입점·외부 앱 연동 검증
        ↓
6. 논의 포인트 MD
        ↓
7. §14 체크리스트 전 항목 통과 → PR
```

> 이 순서를 어겼다면 어디서 거꾸로 갔는지 PR 본문에 명시. 단계 건너뛰기는 회귀 비용으로 직결된다.
