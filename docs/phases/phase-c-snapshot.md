# Phase C — Snapshot 테스트 + UI 구현

> screen-tdd-prompt 스킬의 **Gate 1C + Gate 3** 운용 가이드. Phase B 종료 후에만 이 문서를 연다.

## 진입 조건

- [ ] Phase B 종료 조건 전부 통과 (`docs/<TICKET>/ui-test-cases.md` 완성)

## 의존성 추가

`pointfreeco/swift-snapshot-testing`을 SPM 의존성으로 추가:

1. `Tuist/Package.swift`(또는 `Project.swift`의 테스트 타겟 dependencies)에 추가
2. `tuist install && tuist generate`
3. 테스트 타겟 `PickflowTests`에 `SnapshotTesting` 모듈 import 가능 확인

이미 추가되어 있으면 그대로 사용. 첫 도입 PR이면 이 PR에서 같이 들어감.

## 작업 흐름 (RED → SwiftUI 작성 → GREEN, 케이스 단위 반복)

```
1. ui-test-cases.md의 1행 → SnapshotTests의 1 케이스로 옮김
2. assertSnapshot(of: view, as: .image(...)) 호출만 작성 (구현 없이)
3. xcodebuild test → "no reference snapshot" 실패 (RED 등가)
4. 대응되는 SwiftUI 컴포넌트 구현 / 보강
5. 1차 record 모드로 스냅샷 생성 (isRecording = true 잠시)
6. 생성된 PNG를 직접 눈으로 확인 → ui-test-cases.md "기대 시각 결과"와 일치하는지 비교
7. 일치하면 record OFF → 다시 테스트 → GREEN
8. 다음 케이스
```

> 5번에서 record 한 번 켜고 끄는 걸 잊지 말 것. 켜진 채 머지되면 모든 테스트가 무조건 통과해 회귀 보호 0.

## 테스트 파일 구성

- `PickflowTests/<Screen>SnapshotTests.swift` (메인 화면)
- 컴포넌트가 많으면 `PickflowTests/<Screen>/<Component>SnapshotTests.swift`로 분할
- `__Snapshots__/` 디렉토리는 테스트 파일 옆에 자동 생성. 디렉토리째 git 추적

## 고정값 (전 케이스 동일)

| 항목 | 값 | 이유 |
|---|---|---|
| 디바이스 | `.iPhone15` (또는 프로젝트 표준) | 디바이스마다 픽셀 다르면 회귀 식별 어려움 |
| 언어/지역 | `ko_KR` | 프로덕트 기본. 다국어 시작하면 별도 매트릭스 |
| DynamicType | `.large` (기본), 접근성 케이스만 `.accessibilityExtraLarge` | ui-test-cases.md 컬럼과 일치 |
| Appearance | Light / Dark 둘 다 (별도 케이스) | 한 행에 묶지 않는다 |
| 시간 | `clock` 주입값 고정 (예: 2025-04-26 19:00 KST) | 시간 의존 컴포넌트(일몰 progress 등)의 결정성 |
| 디바이스 ID/UUID | mock 고정 | 공유 시나리오 결정성 |
| 이미지 로드 | placeholder 직접 주입 또는 동기 mock | 비동기 이미지로 인한 플레이키 방지 |

## record 모드 운용 규칙

- 새 케이스 추가 시 1회만 record → 즉시 OFF → 커밋
- 의도적 시각 변경 시: PR 본문에 "왜 변경되었는지" + before/after 스크린샷 첨부 후 record
- 테스트 깨졌다고 분석 없이 record 덮어쓰기 → **금지** (안티 패턴)
- record는 단일 케이스 단위로. 전체 record(`SnapshotTesting.isRecording = true`)는 코드에 박지 않음

## Figma 노드 비교 루프 (Phase C 마무리)

화면 프롬프트 §11 표 기준으로 컴포넌트별 1회씩:

1. `mcp__claude_ai_Figma__get_screenshot` (fileKey + nodeId)
2. 우리 스냅샷과 시각 비교
3. 어긋남 발견 → SwiftUI 수정 → record → 재비교
4. 이상 없을 때까지 루프

## 종료 조건

- [ ] ui-test-cases.md의 모든 행에 대응되는 스냅샷 케이스 존재
- [ ] 매트릭스 전 케이스 스냅샷 green
- [ ] `__Snapshots__/` PNG diff가 PR 본문에 첨부됨
- [ ] record 모드 갱신은 의도적 변경에만 사용했음 (블라인드 record 0건)
- [ ] 시뮬레이터/언어/DynamicType/Appearance 고정값이 테스트 코드에 명시
- [ ] §11 Figma 비교 루프 1회 이상 통과
- [ ] `SWIFT_STRICT_CONCURRENCY: complete` 빌드 경고/에러 0
- [ ] 시뮬레이터에서 디버그 진입점(§12)으로 실제 화면 확인

## 안티 패턴

- 스냅샷 깨짐 → 분석 없이 record로 덮어쓰기 → 회귀를 정상화
- 테스트마다 `record = true` 유지 → CI에서 항상 통과 → 회귀 감지 불가
- 시뮬레이터/언어를 케이스마다 다르게 설정 → 환경 의존 픽셀 차이로 플레이키
- 비동기 이미지 로딩이 끝나기 전 스냅샷 찍힘 → 플레이키. mock으로 동기 주입
- 시간 의존 컴포넌트에 실제 `Date()` 사용 → 테스트 시각마다 다른 스냅샷
- ui-test-cases.md에 없는 케이스를 추가하면서 표 갱신은 안 함 → 표가 더 이상 단일 진실 소스가 아님

## 머지 전 최종 체크

- 화면 프롬프트 §14 마감 체크리스트의 모든 게이트 항목이 체크되어 있는지 확인
- §14가 비어 있으면 거기 먼저 채우고 머지 시도
