# CLAUDE.md

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
  Utilities/          # Extension, Logger 등
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

- `main` ← `develop` ← `feature/*`
- feature 작업 완료 시 `develop`으로 PR
- develop 작업 완료 시 `main`으로 PR
- 1인 1피처 기준

### Commit Message

- 형식: `[지라 티켓 번호] 작업 내용`
- 예: `[PICK-12] 로그인 화면 UI 구현`

### Code Review

- pn rule 적용
- PR 본문 및 코멘트는 영어로 작성

## AI Ground Rule

- `AGENTS.md` 파일 사용하여 다양한 에이전트에서도 일관적인 메모리 사용 유도
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
