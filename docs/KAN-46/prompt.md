# [KAN-46] 로그인 진입 플로우 통합 구현 — 통합 프롬프트

> 이 문서는 Claude / Codex 같은 AI 에이전트에게 KAN-46 작업을 한 번에 지시하기 위한 통합 프롬프트다.
> 기존에 분리 예정이었던 KAN-47, KAN-48, KAN-49, KAN-50 범위는 모두 KAN-46에 흡수되었다.

---

## 0. 역할 지시

너는 `Pickflow` iOS 앱의 시니어 iOS 엔지니어다.
프로젝트의 `AGENTS.md`와 레이어 규칙(App → Feature → Common → Core)을 준수하고,
Swift 6 + SwiftUI + Swift Concurrency 스타일로 코드를 작성한다.

---

## 1. 티켓 개요

- **Jira Key**: KAN-46
- **Feature 브랜치**: `feature/KAN-46`
- **목표**: 로그인 진입 화면부터 카카오 로그인 SDK 연동, 백엔드 로그인 연결, 토큰 저장 준비, 자동 로그인 진입점, 위치권한 삽입 훅까지 로그인 런치 플로우 전체를 한 티켓으로 구현한다.

이번 티켓의 범위:
- 비로그인 사용자를 위한 `LoginView`
- `KakaoSDK` 기반 access token 획득
- `AuthService.signInWithKakao(...)`로 백엔드 로그인 연결
- 토큰 저장 지점 및 저장 인터페이스 반영
- 앱 런치 시 인증 상태 조회 진입점 정리
- 홈 최초 진입 전 위치권한 삽입 훅 정리

메인 화면은 여전히 `Home (WIP)` placeholder로 두어도 된다.

---

## 2. 디자인 명세

레퍼런스는 Figma `node-id=686:24474` 기준이다.

- 배경: 순수 블랙 베이스 위에 좌상단 회색 블러 glow + 우하단 오렌지 블러 glow 2개
- 중앙 컨텐츠:
  - 로고: `70x70`
  - 로고 ↔ 헤드라인 간격: `32pt`
  - 헤드라인 ↔ 서브카피 간격: `32pt`
  - 헤드라인: `Pretendard Bold 28`, 흰색
  - 서브카피: `Pretendard Medium 13`, `#E6E6E6` 계열
- CTA 버튼:
  - 높이 `56pt`
  - 좌우 마진 `16pt`
  - 코너 `8pt`
  - 하단 기준 Figma 레이아웃에 맞게 배치
  - 배경 `#FEE500`
  - 텍스트/아이콘 `#1E2124` 계열

폰트는 반드시 `pretendard(...)` 토큰 사용.

---

## 3. 현재 코드 전제

현재 저장소에는 아래가 이미 구현되어 있다.

- `LoginView`, `LoginViewModel`, `KakaoLoginButton`
- `AuthServiceProtocol`, `AuthService`, `AuthEndpoint`, `AuthDTO`
- `AppRootView` 기반 로그인/홈 분기
- `AppLogoMark` 에셋
- Figma 기준 1차 UI 정렬

추가로 이미 준비된 설정:
- `Tuist/Package.swift`에 Kakao SDK dependency 존재
- `AppInfoPlist.swift`에
  - `KAKAO_NATIVE_APP_KEY`
  - `KAKAO_CALLBACK_SCHEME`
  - `LSApplicationQueriesSchemes`
  가 포함됨
- `Configs/Common.xcconfig`와 `Configs/GoogleService-Info.plist` placeholder 존재

---

## 4. 구현 범위

### 4.1 UI

- 로그인 화면은 Figma 기준으로 계속 보정
- background glow, spacing, button radius, text color 모두 Figma 기준 우선

### 4.2 Kakao SDK 연동

- 앱 시작 시 Kakao SDK 초기화
- 로그인 버튼 탭 시:
  - `UserApi.isKakaoTalkLoginAvailable()` 확인
  - 가능 시 `loginWithKakaoTalk()`
  - 실패 시 fallback 가능 케이스는 `loginWithKakaoAccount()`
  - 불가 시 바로 `loginWithKakaoAccount()`
- 성공 시 `OAuthToken.accessToken`을 반환받아 백엔드 로그인에 사용

### 4.3 서비스 경계

- `AuthService`는 계속 백엔드 `/auth/kakao` 통신만 담당
- Kakao SDK 직접 호출은 별도 provider에서 담당

권장 파일:

```
Pickflow/Sources/Core/Services/
├── KakaoAuthProvider.swift
└── Protocols/
    └── KakaoAuthProviderProtocol.swift
```

### 4.4 ViewModel

`LoginViewModel`은 아래 둘을 주입받는다.

```swift
private let authService: AuthServiceProtocol
private let kakaoAuthProvider: KakaoAuthProviderProtocol
```

로그인 시:

```swift
let kakaoAccessToken = try await kakaoAuthProvider.obtainAccessToken()
let response = try await authService.signInWithKakao(kakaoAccessToken: kakaoAccessToken)
```

### 4.5 DI

`AppContainer.registerDependencies()`에 `KakaoAuthProviderProtocol` 등록 추가.

### 4.6 토큰 저장

이 티켓에서 토큰 저장 위치와 호출 지점까지 같이 정리한다.

- 최소 요구:
  - `response.accessToken`
  - `response.refreshToken`
  저장이 가능한 구조를 만든다.
- 실제 저장소 구현이 없으면 `TokenStoreProtocol` / `KeychainTokenStore`를 함께 추가해도 된다.

### 4.7 자동 로그인

`AuthService.currentAuthState()`는 더 이상 단순 스텁으로 두지 않는다.

목표:
- 저장된 토큰이 있으면 `.signedIn(...)`
- 없으면 `.signedOut`

토큰 유효성 재검증까지는 반드시 필요하지 않다.
최소한 저장된 토큰 존재 여부 기반 복구는 이 티켓 범위다.

### 4.8 위치권한 훅

위치권한 UI 자체를 완성할 필요는 없지만, 로그인 성공 후 홈으로 가는 지점에서 위치권한 흐름을 끼울 수 있게 훅은 정리한다.

예:

```swift
// TODO(KAN-46): 위치권한 팝업/온보딩 삽입 지점
```

---

## 5. 에러 처리

- 사용자 취소는 일반 실패와 구분
- Kakao SDK 실패는 사용자용 메시지로 정리
- 백엔드 인증 실패는 기존 `AuthError` 매핑 유지

예시:

```swift
enum KakaoAuthError: LocalizedError {
    case cancelled
    case loginFailed
    case invalidToken
    case underlying(Error)
}
```

---

## 6. 체크리스트

- [ ] `LoginView` Figma 기준 최종 정렬
- [ ] `KakaoAuthProviderProtocol` 추가
- [ ] `KakaoAuthProvider` 구현
- [ ] `PickflowApp`에서 Kakao SDK 초기화
- [ ] `LoginViewModel`이 provider를 사용하도록 변경
- [ ] `AppContainer`에 DI 등록 추가
- [ ] 로그인 성공 후 토큰 저장 처리
- [ ] `currentAuthState()`에서 저장된 토큰 기반 자동 로그인 분기
- [ ] 위치권한 삽입 훅 정리
- [ ] Preview/Mock 컴파일 유지
- [ ] `tuist generate`
- [ ] Xcode 빌드 성공

---

## 7. 커밋 / PR 가이드

- 커밋 메시지 형식: `[KAN-46] ...`
- PR 본문 및 코멘트는 영어
- 가능하면 커밋은 기능 단위로 분리:
  1. UI/Figma 정렬
  2. Kakao SDK provider + DI
  3. 토큰 저장 + 자동 로그인
  4. 위치권한 훅 / 마감 정리

---

## 8. 주의사항

- `Configs/Common.xcconfig`의 `KAKAO_NATIVE_APP_KEY`, `KAKAO_CALLBACK_SCHEME`가 placeholder면 실제 로그인은 동작하지 않는다.
- `GoogleService-Info.plist`도 placeholder 상태일 수 있으므로 Firebase 동작은 별도 확인 필요.
- `KAN-47`, `KAN-48`, `KAN-49`, `KAN-50`으로 분리하려던 항목은 더 이상 후속 티켓으로 가정하지 않는다. 모두 KAN-46 구현 범위 안에서 처리한다.
