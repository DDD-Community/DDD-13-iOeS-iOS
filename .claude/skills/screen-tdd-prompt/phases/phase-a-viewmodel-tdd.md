# Phase A — ViewModel 단위 테스트 (Mock 기반)

> screen-tdd-prompt 스킬의 **Gate 1A** 운용 가이드. Phase A에 들어갈 때 Claude가 이 문서를 읽는다. 끝나기 전엔 Phase B 문서를 열지 않는다.

## 진입 조건

다음 모두 충족 시에만 Phase A 시작:
- [ ] 화면 프롬프트(`docs/<TICKET>/<slug>-implementation-prompt.md`) §9.1 컬러 매트릭스 채워짐 (TODO 0개)
- [ ] §9.2 아이콘/이미지 매트릭스 채워짐 (TODO 0개)
- [ ] §3 API 매핑 표 확정
- [ ] §6 ViewModel 시그니처(주입 의존성 포함) 합의됨

하나라도 미충족이면 화면 프롬프트로 돌아가 합의부터 끝낸다.

## 셋업

테스트 타겟 `PickflowTests`는 KAN-51부터 존재. 신규 셋업 불필요.

추가할 것:
- `PickflowTests/Helpers/Mock<ServiceName>.swift` — 화면이 새로 의존하는 서비스마다 한 개. 기존 패턴(KAN-51 `MockSpotService` 등) 참고
- `PickflowTests/<Screen>ViewModelTests.swift` — 본 단계의 작업 파일

Mock은 다음 최소 기능을 갖춘다:
- 호출 카운트 (`callCount: Int`)
- 마지막 인자 (`lastArgs: ...`)
- 응답 주입 (`stubResult: Result<T, Error>`) 또는 `var responder: (Args) -> Result<T, Error>`

## 작업 흐름 (RED → GREEN → REFACTOR, 인터랙션 단위 반복)

```
1. 테스트 1개 작성              ← 메서드 시그니처/기대 상태 정의
2. xcodebuild test → RED 확인
3. ViewModel에 최소 구현 추가   ← 그 테스트만 통과시킬 정도
4. xcodebuild test → GREEN 확인
5. 필요하면 리팩토링            ← 테스트는 계속 GREEN 유지
6. 다음 인터랙션으로
```

## 테스트 메서드 네이밍

`{상황}_{조건}_{기대결과}` 한국어 패턴 사용 (KAN-51 선례 일치):

```swift
func test_onAppear_정상응답_상태가loaded로전환된다() async throws { ... }
func test_toggleBookmark_API실패시_상태가롤백되고toast가설정된다() async throws { ... }
func test_openExternalApp_미설치면_AppStoreURL을연다() { ... }
```

async 액션은 `func test_...() async throws`. `XCTestCase` + `@MainActor` 클래스로.

## 화면별 표준 테스트 셋 (체크해 보고 빠진 게 있으면 추가)

- 데이터 로드: 성공 / 실패 / 사전 권한·좌표 누락
- 토글 류: 낙관적 업데이트 → 실패 시 롤백 → 토스트
- 도메인 특수 응답 코드 처리 (예: 409 Conflict를 성공으로 간주)
- 외부 앱 연동: 설치 시 / 미설치 시 분기
- 공유/fire-and-forget API: 본 액션과 부가 액션의 독립성 (부가 실패해도 본 진행)
- 닫기/dismiss 플래그
- 에러 메시지 포맷 (사용자 노출 텍스트라면 정확히 명시)

## 종료 조건

다음 모두 통과해야 Phase B 진입:

- [ ] ViewModel 관련 테스트 100% green (`xcodebuild test -workspace Pickflow.xcworkspace -scheme Pickflow -destination 'platform=iOS Simulator,name=iPhone 15'`)
- [ ] `SWIFT_STRICT_CONCURRENCY: complete` 빌드 경고/에러 0
- [ ] **`Pickflow/Sources/Feature/<Screen>/` 하위에 SwiftUI 뷰 파일 0개** ← 직렬성 자가 점검
- [ ] Preview 파일도 추가되지 않음
- [ ] 인터랙션별 테스트가 화면 프롬프트 §6에서 정의한 모든 액션을 커버

## 안티 패턴

- "테스트 다 같이 작성하고 한꺼번에 구현" — RED 단계가 사라져 단순 작성 검증으로 전락
- View Preview/SwiftUI 코드를 "스파이크"라며 같이 작성 — Phase A 종료 자가 점검 항목 위반
- Mock에 실제 네트워크 동작을 흉내내는 분기 추가 — 단위 테스트 결정성 훼손. Stub은 단순 응답 주입에 그쳐야 함
- async 테스트에서 `Task { ... }` 안쪽 결과를 `try await` 없이 sleep으로 대기 — 플레이키 원인. `await viewModel.action()`이 끝난 시점이 곧 검증 시점이 되도록 ViewModel API 설계
- 테스트가 private 내부 상태를 들여다봄 — `@Published` 외부 관찰 가능 상태로 검증

## 다음 단계

Phase A 종료 조건 모두 통과 → `phase-b-ui-cases.md` 열기.
