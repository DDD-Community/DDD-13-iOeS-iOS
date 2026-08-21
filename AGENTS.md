# AGENTS.md

## Project Overview

- **프로젝트명**: Pickflow
- **플랫폼**: iOS
- **언어**: Swift

## 스펙

- **최소버전**: 26.0
- **UI 프레임워크**: SwiftUI
- **의존성 관리 도구**: `SPM`
- **프로젝트 생성/구성 도구**: `Tuist`
- **네트워크 라이브러리**: `Alamofire`
- **DI 라이브러리**: `Swinject`
- **아키텍처**: 모놀로식
- **Swift 6** + **Swift Concurrency** (async-await)

### 앱 내 레이어

```
App → Feature → Common → Core
                          Core도 Common 모름
```

| 레이어 | 역할 |
|--------|------|
| **Core** | 서비스 프로토콜/구현체, 네트워크, DB, DI, 유틸리티 |
| **Common** | 공통 UI 컴포넌트, 디자인 시스템 |
| **Feature** | 화면 단위 기능, Service 프로토콜 주입받아 사용 |
| **App** | DI 조립, 앱 진입점 |

### 의존성 방향

```
App     ──→ Feature, Common, Core
Feature ──→ Common, Core
Common  ──→ Core
Core    ──→ 없음 (완전 독립)
```

### Core 내부 구조

```
Core/
  Services/
    Protocols/        # 서비스 프로토콜 정의
    (구현체)           # 서비스 구현체
  Network/            # 네트워크 매니저, API 엔드포인트
  Database/           # DB 매니저
  DI/                 # DI 컨테이너 프로토콜 및 구현
  Utilities/          # Extension 등
```

### App에서 DI 조립

```swift
// App/AppContainer.swift
let container = DIContainer()
container.register(UserServiceProtocol.self) { UserService() }
container.register(AuthServiceProtocol.self) { AuthService() }
```

## Git 협업 방식

### Workflow

`develop` 이 trunk 다. `main` 은 쓰지 않는다.

```
feature/* ──PR──> develop ──[Create Release]──> release/x.y.z
                     ^                              │
                     │                              ├─ QA 수정 PR
                     │                              ├─ TestFlight 배포
                     │                              ├─ 태그 vx.y.z
                     └──────백머지 PR───────────────┘
```

- feature 작업 완료 시 `develop` 으로 PR
- 배포할 때가 되면 **Create Release** 워크플로로 `release/x.y.z` 를 만든다.
  버전 상향 커밋이 이 브랜치에 함께 올라간다 (아래 참고)
- QA 중 나온 수정은 `release/x.y.z` 로 PR 한다. **feature 를 release 로 직접 머지하지 않는다**
- 배포·태깅이 끝나면 `release/x.y.z` 를 `develop` 으로 백머지해 버전과 수정분을 회수한다
- release 브랜치가 열려 있어도 다음 기능은 `develop` 에 계속 쌓는다 (동시 릴리즈 대응)
- 1인 1피처 기준

> `develop` 과 `release/**` 로 향하는 PR 에서 CI(유닛 테스트·빌드 검증)가 돈다.

### Commit Message

- 형식: `[지라 티켓 번호] 작업 내용`
- 예: `[PICK-12] 로그인 화면 UI 구현`

### Code Review

- pn rule 적용
- PR 본문 및 코멘트는 영어로 작성

## 버전 관리 & 배포

> 팀 합의 사항. 논의 배경: [Discussion #68](https://github.com/DDD-Community/DDD-13-iOeS-iOS/discussions/68)

### 두 숫자를 분리

| 항목 | 키 | 의미 | 관리 |
|------|-----|------|------|
| **마케팅 버전** | `CFBundleShortVersionString` | 유저·스토어에 보이는 버전 (1.2.0) | 수동 (제품 결정) |
| **빌드 넘버** | `CFBundleVersion` | 같은 버전 내 빌드 구분 (19, 20…) | 자동 (fastlane `latest_testflight_build_number + 1`) |

원칙: **마케팅 버전은 사람이, 빌드 넘버는 자동으로.** TestFlight에 아무리 자주 올려도 마케팅 버전은 고정하고 빌드 넘버만 증가한다. (`1.3.0 (20) → (21) → (22)…`)

### 마케팅 버전 = SemVer (MAJOR.MINOR.PATCH)

유저가 기능을 사용하는 관점을 기준으로 구분한다.

- **PATCH** (`1.2.N`): 버그 수정·소규모 개선 (핫픽스)
- **MINOR** (`1.N.0`): 기능 **추가·수정(개편)** — 하위호환
- **MAJOR** (`N.0.0`): 기능 **삭제·브레이킹**. 아래 중 하나라도 해당하면 MAJOR로 올린다.
  - 기존 사용자 데이터/로컬 저장소 마이그레이션이 필요하고 되돌릴 수 없음
  - 최소 지원 iOS를 올려 일부 기기가 업데이트를 못 받음
  - 사용자가 의존하던 기능을 제거함
  - 핵심 플로우를 전면 재설계해 사용자가 다시 배워야 함
  - (문서화된 예외) PM이 "이건 x.0으로 낸다"고 명시적으로 결정

### 단일 소스

버전은 한 곳에서만 수정한다.

```swift
// Tuist/ProjectDescriptionHelpers/ProjectEnvironment.swift
public static let marketingVersion = "1.1.0"   // ← 이 줄만 수정
```

`BuildSettings.swift`(MARKETING_VERSION)와 `AppInfoPlist.swift`(CFBundleShortVersionString)가 이 상수를 함께 참조한다.

### 팀 규칙

- ✅ 마케팅 버전 변경은 **별도 커밋** (`[TICKET] 버전 x.y.z`)
- ✅ 릴리즈마다 **git 태그**, 접두사 `v` 사용 (`v1.1.0`) — GitHub Actions `v*` 트리거와 시각적 관례에 맞춤
- ✅ 기능 릴리즈 = MINOR, 핫픽스 = PATCH
- ✅ 빌드 넘버는 **자동**, 손대지 않기
- ✅ 스토어에 출시된 버전 번호는 **재사용 금지**
- ✅ 버전 상향은 **Create Release 워크플로**로 실행한다 (아래 참고)
- 🔜 태그 자동 생성은 아직 수동 (TestFlight Deploy 성공 시 자동화 예정)

### Create Release 워크플로

Actions → **Create Release** → Run workflow 에서 올릴 단위만 고르면,
`develop` 에서 릴리즈 브랜치를 자르면서 버전 상향 커밋까지 함께 올린다.

| 입력 | 설명 |
|------|------|
| `bump` | `patch` / `minor` / `major` — 현재 버전 기준으로 계산 |
| `version` | 직접 지정 (예: `1.3.0`). 넣으면 `bump` 는 무시 |
| `ticket` | 커밋 제목 prefix (기본 `RELEASE`) |

버전 커밋이 보호 대상인 `develop` 이 아니라 **새로 만드는 `release/x.y.z` 에 올라가므로
PR·승인·룰셋 bypass 가 필요 없다.** 워크플로가 브랜치를 만들고 그대로 푸시한다.

이후는 사람이 진행한다.

1. QA 중 나온 수정은 `release/x.y.z` 로 PR (CI 가 돈다)
2. **TestFlight Deploy** 워크플로를 `branch=release/x.y.z` 로 실행
3. 배포 확정 후 태그 `vx.y.z`
4. `release/x.y.z` → `develop` 백머지 PR

현재 버전과 같거나 낮은 값, 이미 태그가 있는 값, 이미 있는 브랜치는 워크플로가 거부한다.

> `develop` 의 `marketingVersion` 은 백머지 시점에 올라간다. 릴리즈 브랜치가 열려 있는 동안
> develop 이 이전 버전을 가리키는 것은 정상이다.

### ⚠️ 배포 함정 (재발 방지)

1. **Info.plist 버전은 반드시 리터럴** — Tuist 기본 plist는 `CFBundleShortVersionString`을 리터럴로 하드코딩하고 `$(MARKETING_VERSION)` 빌드 변수는 archive 시 치환되지 않아 리터럴 문자열이 그대로 업로드된다. 그래서 실제 버전 문자열을 직접 박아야 한다(현재 `ProjectEnvironment.marketingVersion`로 처리).
2. **스토어 출시 버전 번호 재사용 금지** — 한 번 App Store에 승인/출시된 버전은 train이 닫혀 재업로드 불가 (`Invalid Pre-Release Train, 90186`).
3. **TestFlight Deploy는 `branch` input 기준** — 워크플로가 `branch` input(기본 `develop`)을 checkout한다. 특정 브랜치 배포 시 `gh workflow run "TestFlight Deploy" -f branch=feature/XXX`.

## AI Ground Rule

- 이 파일(`AGENTS.md`)이 모든 AI 에이전트의 **단일 진실 소스(Single Source of Truth)**
- `CLAUDE.md`는 이 파일을 가리키는 심볼릭 링크 (`ln -s AGENTS.md CLAUDE.md`)
- 정해진 의사결정에 대해서도 필요시 문서화
- 모든 작업에 대해서 허용하며, PR 리뷰 및 코멘트에는 사람이 직접 책임

### Service 생성 시 필수 작업

Core에 새로운 Service를 생성할 때 아래 작업을 **모두** 수행해야 한다:

1. `Core/Services/Protocols/`에 `{Name}ServiceProtocol.swift` 생성
2. `Core/Services/`에 `{Name}Service.swift` 구현체 생성 (NetworkManagerProtocol 주입)
3. **`App/AppContainer.swift`의 `registerDependencies()`에 DI 등록 추가**

```swift
// 예시: MapService 추가 시
container.register(MapServiceProtocol.self) { MapService(networkManager: networkManager) }
```

> 3번을 빠뜨리면 런타임에 resolve 실패로 크래시가 발생하므로 반드시 함께 수행한다.

### 관련 문서

```
AGENTS.md
ARCHITECTURE.md
docs/
```

## Code Style

- Swift 공식 API Design Guidelines 준수
- 들여쓰기: 4 spaces
- 네이밍: camelCase (변수/함수), PascalCase (타입/프로토콜)

## Commands

- 빌드: `Cmd + B` (Xcode)
- 테스트: `Cmd + U` (Xcode)
- 프로젝트 생성: `tuist generate`

### Tuist Generate 규칙

아래 변경이 발생하면 **반드시 `tuist generate`를 실행**해야 한다:

- Swift 파일 생성 또는 삭제
- `Project.swift` 또는 `Tuist/` 하위 설정 파일 수정
- 외부 의존성 추가/제거

> Tuist 프로젝트는 glob(`Pickflow/Sources/**`)으로 소스를 수집하므로, 파일 추가/삭제 후 `tuist generate`를 하지 않으면 Xcode 프로젝트에 반영되지 않는다.
