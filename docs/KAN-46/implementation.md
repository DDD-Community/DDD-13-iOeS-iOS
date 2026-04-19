# [KAN-46] 로그인 진입 플로우 — 구현 기록

> 통합 프롬프트([prompt.md](./prompt.md)) 기준으로 구현 상태를 기록한다.
> 기존 분리 예정이던 KAN-47, KAN-48, KAN-49, KAN-50 범위는 모두 KAN-46에 포함하는 것으로 결정되었다.

## 현재 방향

- 브랜치: `feature/KAN-46`
- 기준: 로그인 UI만이 아니라 로그인 런치 플로우 전체를 한 브랜치에서 마감
- 포함 범위:
  - 로그인 진입 화면
  - Kakao SDK 로그인 연동
  - 백엔드 `/auth/kakao` 연동
  - 토큰 저장 지점 정리
  - 자동 로그인 진입점 정리
  - 위치권한 삽입 훅 정리

## 이미 반영된 것

- `LoginView`, `LoginViewModel`, `KakaoLoginButton`
- `AuthDTO`, `AuthEndpoint`, `AuthServiceProtocol`, `AuthService`
- `AppRootView` 기반 로그인/홈 라우팅
- `AppLogoMark` 에셋 추가
- Figma 기준 UI 보정
  - background glow
  - spacing
  - text colors
  - button placement
- `tuist install`
- `tuist generate`
- Xcode simulator build 성공

## 현재 작업 파일

```
Pickflow/Sources/
├── App/
│   ├── AppContainer.swift
│   ├── AppRootView.swift
│   ├── ContentView.swift
│   └── PickflowApp.swift
├── Core/
│   └── Services/
│       ├── KakaoAuthProvider.swift
│       └── Protocols/
│           └── KakaoAuthProviderProtocol.swift
└── Feature/
    └── Auth/
        ├── LoginView.swift
        └── LoginViewModel.swift
```

## 구현 의사결정

### Kakao SDK 경계

- `AuthService`는 계속 백엔드 통신만 담당
- Kakao SDK는 `KakaoAuthProvider`로 분리
- `LoginViewModel`은 provider와 service를 주입받아 orchestration만 수행

### 로그인 라우팅

- `AppRootViewModel.bootstrap()`는 자동 로그인 진입점
- 저장된 토큰을 읽어 `.signedIn` / `.signedOut`을 결정하는 단일 진입점으로 유지

### 위치권한

- 홈 진입 직전 또는 직후에 위치권한 흐름을 끼울 수 있는 훅을 유지
- 실제 권한 UI를 넣더라도 라우팅 구조를 다시 뜯지 않게 하는 것이 목적

## TODO 정리 기준

이제 아래 항목은 “후속 티켓”이 아니라 `KAN-46` 내부 남은 작업으로 본다.

- Kakao SDK 실연동 마감
- access / refresh token 저장
- 저장된 토큰 기반 자동 로그인
- 위치권한 흐름 삽입

grep:

```bash
rg "TODO\\(KAN-46" Pickflow/Sources
rg "TODO\\(resource" Pickflow/Sources
```

## 검증 상태

- `tuist generate`: 성공
- `xcodebuild -workspace Pickflow.xcworkspace -scheme Pickflow -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' build`: 성공

## 남은 확인 사항

1. `KAKAO_NATIVE_APP_KEY`
2. `KAKAO_CALLBACK_SCHEME`
3. 실제 Firebase `GoogleService-Info.plist`
4. `is_new_user` true일 때 라우팅 목적지
5. 위치권한 UX 세부 흐름

## 메모

- 문서상 KAN-47~50이라는 이름은 더 이상 구현 경계를 뜻하지 않는다.
- 현재 기준으로는 모두 `KAN-46` 마감 범위로 취급한다.
