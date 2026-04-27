# [KAN-46] 로그인 플로우 마감 작업 — 추가 프롬프트

> 이 문서는 현재 `feature/KAN-46` 브랜치 상태를 기준으로, 아직 남아 있는 로그인 플로우 마감 작업만 이어서 처리하기 위한 추가 프롬프트다.
> 이미 완료된 UI/Figma 보정, Kakao SDK provider 도입, 앱 초기화, 빌드 통과는 다시 하지 않는다.

---

## 0. 역할 지시

너는 `Pickflow` iOS 앱의 시니어 iOS 엔지니어다.
프로젝트의 `AGENTS.md`와 레이어 규칙(App → Feature → Common → Core)을 준수하고,
Swift 6 + SwiftUI + Swift Concurrency 스타일로 작업한다.

---

## 1. 현재 상태

이미 완료된 것:

- `LoginView`, `KakaoLoginButton`, `LoginViewModel`
- `AuthService`, `AuthEndpoint`, `AuthDTO`
- `AppRootView` 기반 로그인/홈 라우팅
- `KakaoAuthProviderProtocol`, `KakaoAuthProvider`
- `PickflowApp`의 Kakao SDK 초기화
- `tuist generate` 성공
- `xcodebuild -workspace Pickflow.xcworkspace -scheme Pickflow -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' build` 성공

남아 있는 것:

1. 로그인 성공 후 access/refresh token 저장
2. 저장된 토큰 기반 자동 로그인 복구
3. 위치권한 삽입 훅 정리
4. `is_new_user`는 응답으로만 유지하고 라우팅에는 사용하지 않도록 정리

---

## 2. 목표

이번 추가 작업의 목표는 “앱을 다시 켰을 때 로그인 상태가 복구되는 최소 동작”까지 완성하는 것이다.

즉:

- 카카오 로그인 성공
- 백엔드 `/auth/kakao` 응답 수신
- access / refresh token 저장
- 앱 재실행 시 `currentAuthState()`에서 저장 토큰 읽어 `.signedIn(...)` 반환
- 홈 진입 지점에 위치권한 삽입용 훅 유지

실제 토큰 refresh 요청 자동화까지는 이번 단계에서 필수는 아니다.

---

## 3. 구현 범위

### 3.1 TokenStore 도입

새 파일 권장:

```
Pickflow/Sources/Core/Services/Protocols/
└── TokenStoreProtocol.swift

Pickflow/Sources/Core/Services/
└── KeychainTokenStore.swift
```

최소 인터페이스 예시:

```swift
protocol TokenStoreProtocol: Sendable {
    func save(_ token: AuthToken) throws
    func load() throws -> AuthToken?
    func clear() throws
}
```

저장소는 Keychain 기반 권장.
단, 구현 복잡도가 크면 우선 UserDefaults 임시 구현으로 끝내지 말고 Keychain으로 마무리한다.

### 3.2 DI 등록

`AppContainer.registerDependencies()`에 `TokenStoreProtocol` 등록 추가.

예시:

```swift
container.register(TokenStoreProtocol.self, scope: .container) {
    KeychainTokenStore()
}
```

### 3.3 LoginViewModel 저장 처리

현재 코드:

```swift
let response = try await authService.signInWithKakao(kakaoAccessToken: kakaoAccessToken)
// TODO(KAN-48): response.accessToken / response.refreshToken을 KeyChain에 저장.
```

이 TODO를 실제 구현으로 교체한다.

권장 방식:
- `LoginViewModel`에 `TokenStoreProtocol` 주입
- `AuthToken(accessToken: response.accessToken, refreshToken: response.refreshToken)` 생성
- 로그인 성공 직후 저장

### 3.4 AuthService.currentAuthState() 구현

현재는 `.signedOut` 스텁이다.

이걸 아래 동작으로 변경:

- `TokenStoreProtocol.load()` 시도
- 토큰이 있으면 `.signedIn(token)`
- 없으면 `.signedOut`

주의:
- 네트워크 검증 없이 “저장된 토큰 존재 여부 기반 복구”만 해도 된다
- 나중에 refresh 로직이 필요하면 그때 확장

### 3.5 Logout 헤더 준비

`AuthEndpoint.logout`는 현재 Bearer 헤더가 비어 있다.

이번 단계에서는 아래 둘 중 하나로 처리:

1. `AuthService.signOut()`에 `TokenStoreProtocol`을 주입해서 헤더를 붙일 수 있도록 구조 개선
2. 또는 `AuthEndpoint`가 token을 받는 형태로 바꿈

권장:

```swift
case logout(accessToken: String)
```

그리고 `AuthService.signOut()` 안에서 저장된 토큰을 꺼내 사용.

토큰이 없으면 조용히 `clear()`만 해도 된다.

### 3.6 AppRootView / 라우팅

`AppRootViewModel.bootstrap()`는 현재 이미 `authService.currentAuthState()`를 호출한다.

이번 단계에서는:
- 이 흐름 유지
- 주석의 “스텁” 표현 제거
- signed-in일 때 홈 placeholder로 바로 진입되는지 유지

### 3.7 위치권한 훅 정리

`HomePlaceholderView.task`의 위치권한 TODO는 유지하되, 티켓명이 아니라 현재 통합 범위에 맞는 주석으로 바꾼다.

예:

```swift
// TODO(KAN-46): 홈 최초 진입 시 위치권한 온보딩 삽입
```

### 3.8 신규 유저 플래그 정리

`KakaoSignInResponse.isNewUser`는 백엔드 응답 필드로 유지한다.

이번 단계에서는:
- 로그인 성공 라우팅은 신규/기존 유저 모두 동일하게 홈으로 보낸다.
- `isNewUser`를 UI 상태나 라우팅 분기에 저장하지 않는다.
- 필요 시 추후 분석/기획 변경 시점에만 별도 사용처를 추가한다.

---

## 4. 변경 대상 파일

신규:

```
Pickflow/Sources/Core/Services/Protocols/TokenStoreProtocol.swift
Pickflow/Sources/Core/Services/KeychainTokenStore.swift
```

수정:

```
Pickflow/Sources/App/AppContainer.swift
Pickflow/Sources/App/AppRootView.swift
Pickflow/Sources/Feature/Auth/LoginViewModel.swift
Pickflow/Sources/Core/Services/AuthService.swift
Pickflow/Sources/Core/Network/AuthEndpoint.swift
Pickflow/Sources/Core/Services/Protocols/AuthServiceProtocol.swift
```

필요하면 `ContentView`, Preview mock도 함께 조정.

---

## 5. 체크리스트

- [ ] `TokenStoreProtocol` 추가
- [ ] `KeychainTokenStore` 구현
- [ ] `AppContainer` DI 등록
- [ ] `LoginViewModel`에서 로그인 성공 후 토큰 저장
- [ ] `AuthService.currentAuthState()` 구현
- [ ] `signOut()`가 저장 토큰을 반영하도록 정리
- [ ] 위치권한 TODO 문구를 `KAN-46` 기준으로 통일
- [ ] 신규 유저 분기 TODO 명확화
- [ ] Preview / Mock 컴파일 유지
- [ ] `tuist generate`
- [ ] Xcode 빌드 성공

---

## 6. 검증 기준

최소 완료 조건:

1. 앱 첫 실행 시 비로그인 상태면 `LoginView`
2. 카카오 로그인 성공 후 홈 placeholder 진입
3. 앱 종료 후 재실행 시 저장 토큰이 있으면 로그인 화면을 건너뛰고 홈 placeholder 진입
4. 로그아웃 시 토큰 제거 후 다시 로그인 화면 진입

---

## 7. 주의사항

- `KAKAO_NATIVE_APP_KEY`와 `KAKAO_CALLBACK_SCHEME`가 placeholder면 실제 카카오 로그인은 정상 동작하지 않는다.
- 토큰 저장 구현은 임시 메모리 저장이 아니라 실제 지속 저장소를 사용한다.
- 이번 추가 작업도 모두 `KAN-46` 커밋으로 처리한다.
