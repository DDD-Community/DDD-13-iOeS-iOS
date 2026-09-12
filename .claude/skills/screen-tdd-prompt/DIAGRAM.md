# screen-tdd-prompt 스킬 다이어그램

> `screen-tdd-prompt` 스킬의 동작과 TDD A→B→C 3단계를 그림으로 정리한 문서.
> Mermaid 문법 — GitHub / Notion / 대부분의 마크다운 뷰어에서 렌더링된다.

## 한 줄 요약

새 화면 티켓(KAN-XX) → **TDD 게이트가 강제된 자기완결 구현 프롬프트 MD**로 변환하는 스킬.
실제 화면을 구현하는 게 아니라, 구현 설계도를 찍어낸다.

---

## 1. 스킬 전체 흐름 — "프롬프트 생성 → 화면 구현"

```mermaid
flowchart TD
    A[새 화면 티켓 KAN-XX<br/>Figma 노드 + API 정보] --> B{입력 10항목<br/>다 모였나?}
    B -- 누락 --> Q[사용자에게 질문]
    Q --> B
    B -- 완료 --> C[prompt-template.md 골격 읽기]
    C --> D[docs/TICKET/ 생성]
    D --> E["📄 screen-implementation-prompt.md<br/>(화면별 사실, ~150줄)"]
    D --> F["📄 ui-test-cases.md<br/>(빈 셸, 헤더만)"]
    E --> G[빈 섹션 = 합의 필요<br/>사용자에게 보고]

    G -.생성 끝, 이제 구현.-> H[화면 구현 시작]
    H --> P1

    subgraph TDD[TDD 직렬 3단계 - 절대 병렬 금지]
        direction TB
        P1[Phase A] --> P2[Phase B] --> P3[Phase C]
    end
    P3 --> PR[PR / 머지]

    style E fill:#e3f2fd
    style F fill:#e3f2fd
    style TDD fill:#fff8e1
```

---

## 2. A→B→C 단계 + 게이트 상세

```mermaid
flowchart TD
    START([화면 프롬프트 read]) --> G4

    G4["🚪 Gate 4: 에셋 매트릭스<br/>§9 컬러/아이콘/폰트 토큰 확정<br/>(코딩 시작 전)"]
    G4 --> A

    subgraph A["Phase A — ViewModel 단위 테스트 (로직)"]
        A1[Mock 서비스 작성] --> A2[RED → GREEN → REFACTOR<br/>인터랙션 단위 반복]
        A2 --> A3{{"종료조건: 테스트 100% green<br/>⚠️ SwiftUI 뷰 0줄"}}
    end

    A3 -->|"🚪 Gate 1A 통과"| B

    subgraph B["Phase B — ui-test-cases.md (문서)"]
        B1[8컬럼 표 작성<br/>case id/상태/테마/Light·Dark...] --> B2{{"종료조건: TODO 0개<br/>최소 커버리지 충족"}}
    end

    B2 -->|"🚪 Gate 1B + Gate 2 통과"| C

    subgraph C["Phase C — Snapshot + UI 구현 (비주얼)"]
        C1[swift-snapshot-testing 도입] --> C2[표 1행 = 스냅샷 1케이스<br/>RED→SwiftUI 구현→record 1회→GREEN]
        C2 --> C3[Figma get_screenshot 비교 루프]
        C3 --> C4{{"종료조건: 전 케이스 green<br/>블라인드 record 0건"}}
    end

    C4 -->|"🚪 Gate 1C + Gate 3 통과"| PR([PR / 머지])

    style G4 fill:#ffe0b2
    style A fill:#e8f5e9
    style B fill:#e3f2fd
    style C fill:#f3e5f5
```

---

## 3. 핵심 개념 한 장 요약

```mermaid
flowchart LR
    subgraph 입력
      I1[티켓 ID]
      I2[Figma 노드]
      I3[API 매핑]
      I4[정책/스코프]
    end

    입력 --> SKILL[["⚙️ screen-tdd-prompt<br/>스킬"]]

    SKILL --> OUT["📄 자기완결 구현 프롬프트<br/>(이거 한 장만 읽고 구현 가능)"]

    OUT --> 게이트["4개 강제 게이트<br/>빠지면 머지 금지"]

    게이트 --> P[" Phase A 로직<br/>↓<br/>Phase B 문서<br/>↓<br/>Phase C 비주얼 "]

    style SKILL fill:#fff8e1
    style OUT fill:#e3f2fd
    style 게이트 fill:#ffcdd2
    style P fill:#e8f5e9
```

---

## 단계별 정리표

| | Phase A | Phase B | Phase C |
|---|---|---|---|
| 산출물 | ViewModel + 단위 테스트 | `ui-test-cases.md` 표 | SwiftUI 뷰 + 스냅샷 테스트 |
| 성격 | 로직 | 문서/계획 | 비주얼 |
| 핵심 금지 | 뷰 코드 0줄 | (Phase A 끝나야 진입) | 블라인드 record |
| 운용 가이드 | `docs/phases/phase-a-viewmodel-tdd.md` | `docs/phases/phase-b-ui-cases.md` | `docs/phases/phase-c-snapshot.md` |

## 4개 게이트

| Gate | 무엇 | 왜 |
|---|---|---|
| **1** | TDD A→B→C 직렬 3단계 | 단계 격리 없으면 회귀 보호 무력화 |
| **2** | `ui-test-cases.md` 작성 | 스냅샷 매트릭스의 단일 진실 소스 |
| **3** | swift-snapshot-testing | 비주얼 회귀를 테스트가 잡는 마지막 방어선 |
| **4** | 에셋 입력 매트릭스 | 코딩 후 Figma 재방문 비용 폭발 방지 |

> **왜 직렬인가**: 단계를 섞으면 A에서 뷰를 손대고 B 없이 스냅샷을 찍게 되어,
> 표가 사후 합리화 문서로 전락하고 회귀 보호가 무력화된다.
