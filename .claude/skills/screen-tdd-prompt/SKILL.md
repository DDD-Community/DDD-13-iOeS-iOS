---
name: screen-tdd-prompt
description: Pickflow의 새 화면 티켓(KAN-XX)에 대해 TDD A→B→C 3단계를 강제하는 단일 구현 프롬프트 MD를 생성한다. 사용자가 새 화면 티켓·Figma 노드·API 정보를 들고 와서 "구현 프롬프트 만들어줘" 류로 요청할 때 사용. 결과물은 `docs/<TICKET>/<screen>-implementation-prompt.md` 한 장이며, 이후 Claude가 이 한 장만 읽고도 화면을 구현할 수 있을 만큼 자기완결적이어야 한다.
---

# screen-tdd-prompt

Pickflow의 새 화면을 구현할 때 사용할 **단일 구현 프롬프트 MD**를 생성하는 스킬이다.
KAN-51(스팟 상세) 선례를 기준 골격으로 삼되, 다음 4개 게이트를 **반드시** 포함시킨다:

1. **TDD A→B→C 3단계 엄격 분리** — 단계 건너뛰기 금지, 각 단계의 진입/종료 조건 명시
2. **`docs/<TICKET>/ui-test-cases.md` 작성을 Phase B 산출물로 강제** — 뷰 코드 착수 전 통과 의무
3. **swift-snapshot-testing 게이트** — Phase C 진입 조건이자 머지 전 통과 필수
4. **에셋 입력 매트릭스** — 컬러/아이콘/폰트 토큰을 코딩 시작 전에 표로 확정

## 언제 이 스킬을 쓰는가

- 사용자가 새 화면 티켓(`KAN-XX`)을 가지고 와서 "구현 프롬프트", "통합 프롬프트", "implementation prompt", "TDD 프롬프트" 등을 요청할 때
- 사용자가 Figma 링크 + 화면 단위 작업을 던지면서 "어떻게 시작할지 계획부터 잡아줘" 류로 요청할 때

화면이 아닌 작업(Core 인프라만, 디자인 시스템 토큰만, 빌드 설정 등)에는 사용하지 않는다.

## 산출물

```
docs/<TICKET>/
  ├── <screen-slug>-implementation-prompt.md   ← 메인 결과물
  └── ui-test-cases.md                          ← Phase B에서 채울 빈 셸 (헤더만 미리)
```

## 입력으로 사용자에게 받아야 하는 정보

프롬프트를 만들기 전에 아래 항목이 모두 모였는지 확인한다. 빠진 게 있으면 사용자에게 물어본다.

| # | 항목 | 비고 |
|---|---|---|
| 1 | 티켓 ID | 예: `KAN-71`. Jira URL도 받아두면 좋다 |
| 2 | 브랜치명 | 보통 `feature/KAN-XX`, 이미 체크아웃되어 있다고 가정 |
| 3 | 화면 이름 / slug | slug는 파일명용 kebab-case (예: `spot-detail`) |
| 4 | Figma 파일 키 + 루트 노드 ID | URL에서 추출. node-id의 `-`는 `:`로 변환 |
| 5 | 컴포넌트별 Figma node-id 매핑 | nav/header/section/footer 등 — Phase C UI 검증 루프 표에 들어감 |
| 6 | API 엔드포인트 매핑 | UI 동작 ↔ HTTP method/path/body 표 |
| 7 | 스코프 안/밖 | "이번에 안 함" 항목까지 명시 |
| 8 | 정책 결정 | 일몰 윈도우, 거리 단위, 비로그인 처리 등 사용자 확정 내용 |
| 9 | 외부 앱 연동 | 네이버 지도/공유 sheet 등 nmap 스킴, fallback URL |
| 10 | 에셋 매트릭스 원천 | Figma dev mode hex/icon export — **코딩 시작 전에 확정** |

## 골격 — 프롬프트 템플릿 사용

같은 디렉토리의 `prompt-template.md`를 베이스로 채운다. 템플릿 안에 `{{TICKET}}`, `{{SCREEN_NAME}}` 등 플레이스홀더가 있고, 위에서 받은 정보를 치환한다.

치환 규칙:
- `{{TICKET}}` → `KAN-71`
- `{{SCREEN_NAME}}` → 자연어 화면 이름, 예: `스팟 상세`
- `{{SCREEN_SLUG}}` → kebab-case 파일명 조각, 예: `spot-detail`
- `{{FIGMA_FILE_KEY}}` → `0oGEIr4oCzpvj4bkGtE5Oa`
- `{{FIGMA_ROOT_NODE_ID}}` → `686:18705`
- `{{JIRA_URL}}` → `https://dddios1.atlassian.net/browse/KAN-XX`
- 표·리스트 자리들은 사용자 입력으로 채우거나, 정보가 없으면 `<!-- TODO: 합의 필요 -->` 코멘트와 함께 비워둔다

치환 후 빈 섹션이 남으면 그 섹션이 **현재 시점에 합의되지 않았다는 신호**다. 사용자에게 확인한다.

## 절대 빼지 말아야 할 항목 (강제 게이트)

이 게이트가 빠진 프롬프트는 머지 금지. 템플릿에 이미 포함되어 있으므로 **삭제하지 말 것**:

### Gate 1 — TDD A→B→C 3단계 엄격
- **Phase A — ViewModel 단위 테스트(Mock 기반)**
  - 모든 인터랙션·상태 전이를 테스트로 먼저 작성 → RED → 최소 구현 → GREEN
  - 종료 조건: ViewModel 관련 테스트 100% green. **이 시점까지 SwiftUI View 코드 한 줄도 쓰지 않는다.**
- **Phase B — `docs/<TICKET>/ui-test-cases.md` 작성**
  - 컴포넌트 × 상태(loading/loaded/empty/error) × 테마(노을/윤슬 등) × 디바이스 × DynamicType × Light/Dark 매트릭스 표 확정
  - 종료 조건: ui-test-cases.md가 리뷰어가 이해 가능한 수준으로 채워짐. **이 시점까지 Phase C 스냅샷 테스트/뷰 코드 작성 금지.**
- **Phase C — Snapshot 테스트 + UI 구현**
  - ui-test-cases.md의 각 행을 그대로 swift-snapshot-testing 케이스로 옮김 → RED → SwiftUI 뷰 구현 → GREEN
  - 종료 조건: 매트릭스 전 케이스 스냅샷 green, Figma 노드 비교 루프 1회 이상 완료

각 Phase 진입/종료 조건을 프롬프트에 그대로 박아둘 것.

### Gate 2 — `ui-test-cases.md` 강제
- Phase B 산출물로 명시
- 들어가야 할 컬럼 (최소): `case id`, `컴포넌트`, `상태/입력 조건`, `테마/언어/DynamicType`, `Light/Dark`, `디바이스`, `기대 시각 결과`, `스냅샷 파일명`
- "ui-test-cases.md가 비어 있으면 Phase C 진입 금지"를 마감 체크리스트에 못 박는다

### Gate 3 — swift-snapshot-testing 게이트
- 의존성 추가: `pointfreeco/swift-snapshot-testing` (SPM, Tuist `Project.swift`의 테스트 타겟)
- 머지 전 체크리스트에 다음 포함:
  - 매트릭스 전 케이스 스냅샷 green
  - 의도적 변경분만 record 모드로 갱신, `__Snapshots__/` 디렉토리 diff PR 본문에 첨부
  - 시뮬레이터/언어/DynamicType 고정값 명시 (예: iPhone 15, ko_KR, `.large`, Light/Dark 둘 다)
- "스냅샷 깨짐 → 일단 record로 덮어쓰기"는 명시적 안티패턴으로 금지

### Gate 4 — 에셋 입력 매트릭스
프롬프트에 다음 두 표를 비워두고 사용자가 **Phase A 시작 전에** 채우도록 강제한다:

**컬러 매트릭스**

| 토큰명 | Figma node | hex (Light) | hex (Dark, 있으면) | 용도 |
|---|---|---|---|---|

**아이콘/이미지 매트릭스**

| 에셋명 | Figma node | export 포맷 | 사이즈 (1x/2x/3x) | 용도 |
|---|---|---|---|---|

이 두 매트릭스가 모두 채워진 다음에야 Phase A 시작. 미채움이면 진행 차단.

## 절차 (스킬 호출 시 단계)

1. 사용자에게 위 "입력 정보 10항목" 중 누락된 것 확인
2. `prompt-template.md` 읽어 골격 확보
3. `docs/<TICKET>/` 디렉토리 생성
4. 치환·작성하여 `docs/<TICKET>/<SCREEN_SLUG>-implementation-prompt.md` 저장
5. 빈 셸인 `docs/<TICKET>/ui-test-cases.md`도 같이 생성 (헤더만, 본문은 Phase B에서 채움)
6. 사용자에게 결과 경로와 "비어 있는 섹션"(합의 필요 항목) 목록을 알려줌

## 같이 쓰면 좋은 도구

- `mcp__claude_ai_Figma__get_design_context` — 컬러/아이콘 토큰 추출
- `mcp__claude_ai_Figma__get_screenshot` — 컴포넌트별 비교용 스크린샷
- `mcp__atlassian__*` — Jira 티켓 본문 가져오기
- 기존 선례: `feature/KAN-51` 브랜치의 `docs/KAN-51/spot-detail-implementation-prompt.md`

## 안티 패턴

- 빈 섹션을 "추후"라고 적고 넘어가기 → 합의되지 않은 채 코딩 진입 → Phase A부터 흔들림
- TDD 단계 병렬화 → 단계 의미 사라짐. A→B→C는 직렬이다
- 스냅샷을 "있으면 좋고" 수준으로 약화 → Gate 3 무력화. **머지 차단 조건**으로 유지
- 스냅샷 깨질 때 분석 없이 record로 덮어쓰기 → 회귀를 정상화시킴
- 에셋 매트릭스 없이 코드부터 시작 → Figma 재방문 비용 폭발. 매트릭스가 1차 산출물
