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
