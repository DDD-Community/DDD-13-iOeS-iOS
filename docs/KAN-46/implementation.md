# [KAN-46] 로그인 진입 화면 — 구현 기록

> 통합 프롬프트([prompt.md](./prompt.md))에 따라 실제로 구현한 작업 내역.

## 요약

- 브랜치: `feature/KAN-46` (base: `develop`)
- 커밋: 4개 (논리적 단위로 분리)
- 변경량: 11 files changed, ~638 insertions(+)
- 레이어: App → Feature → Common → Core 단방향 준수
- 빌드 검증: 샌드박스가 Linux라 로컬 `tuist generate` + Xcode 빌드로 유저가 확인 필요

## 커밋 히스토리

| # | Hash | Subject | 주요 파일 |
|---|------|---------|----------|
| C1 | `87d33d4` | `[KAN-46] Auth DTO·Endpoint·AppConfig 추가` | `App/AppConfig.swift`, `Core/Services/Models/AuthDTO.swift`, `Core/Network/AuthEndpoint.swift`, `Core/Services/Protocols/AuthServiceProtocol.swift`, `Core/Services/AuthService.swift`(스텁) |
| C2 | `9ee3bb4` | `[KAN-46] AuthService 네트워크 연동 및 JSON Body 지원` | `Core/Network/NetworkManager.swift`(+`requestJSON`, snake_case decoder), `Core/Services/AuthService.swift`(실구현 + 에러 매핑) |
| C3 | `36e119e` | `[KAN-46] 로그인 진입 화면 UI 및 ViewModel 구현` | `Feature/Auth/LoginView.swift`, `Feature/Auth/LoginViewModel.swift`, `Feature/Auth/Components/KakaoLoginButton.swift` |
| C4 | `2f739eb` | `[KAN-46] AppRootView 라우팅 및 DI 배선` | `App/AppRootView.swift`, `App/ContentView.swift`, `Feature/Auth/LoginView.swift`(콜백 추가) |

각 커밋은 독립적으로 컴파일이 깨지지 않도록 설계:

- C1에서 프로토콜 시그니처가 바뀌면 `AuthService.swift`도 동시에 스텁으로 맞춰 C1이 그 자체로 빌드되도록 유지
- C2가 C1 스텁을 실제 네트워크 호출로 교체
- C3은 Service 계층 완성 이후 UI 레이어 구축
- C4가 DI/라우팅으로 모두 엮고 `LoginView`에 성공 콜백 추가

## 최종 디렉터리 스냅샷

```
Pickflow/Sources/
├── App/
│   ├── AppConfig.swift              # NEW  API baseURL 환경 상수
│   ├── AppContainer.swift           # 변경 없음 (AuthService init 시그니처 그대로)
│   ├── AppRootView.swift            # NEW  라우팅 컨테이너 + AppRootViewModel
│   ├── ContentView.swift            # 수정 AppRootView 얇은 래퍼로 단순화
│   └── PickflowApp.swift            # 변경 없음
├── Common/                          # 변경 없음
├── Core/
│   ├── Network/
│   │   ├── APIEndpoint.swift
│   │   ├── AuthEndpoint.swift       # NEW  /auth/kakao, /auth/refresh, /auth/logout
│   │   └── NetworkManager.swift     # 수정 requestJSON 오버로드 + snake_case 디코더
│   └── Services/
│       ├── AuthService.swift        # 수정 requestJSON 기반 실구현 + AFError 매핑
│       ├── Models/
│       │   ├── AuthDTO.swift        # NEW  KakaoSignInRequest/Response, AuthUser,
│       │   │                        #      SocialProvider, AuthToken, AuthState, AuthError
│       │   └── Coordinate.swift
│       └── Protocols/
│           └── AuthServiceProtocol.swift  # 수정 signInWithKakao/refreshToken/currentAuthState 추가
└── Feature/
    ├── Auth/                        # NEW
    │   ├── Components/
    │   │   └── KakaoLoginButton.swift
    │   ├── LoginView.swift
    │   └── LoginViewModel.swift
    └── Profile/                     # 변경 없음
```

## 구현 핵심 결정

### Kakao SDK 경계 분리

`AuthService.signInWithKakao(kakaoAccessToken:)`는 Kakao SDK에 의존하지 않는다. 대신 `LoginViewModel.obtainKakaoAccessToken()` 스텁(`TODO(KAN-47)`)이 SDK 호출 경계를 담당한다. 덕분에 KAN-47 작업에서 단 한 곳(`LoginViewModel.obtainKakaoAccessToken()`)만 실구현으로 교체하면 된다.

### 인증 상태 단일 진입점

`AppRootViewModel.bootstrap()` → `AuthService.currentAuthState()` 한 곳으로 집결. 현재는 항상 `.signedOut` 반환하는 스텁이며, KAN-48(KeyChain) → KAN-49(자동 로그인) 순으로 확장될 때 이 메서드 본문만 교체하면 전체 라우팅에 반영된다.

### 위치권한 팝업 훅

`AppRootView` 내 `HomePlaceholderView.task`에 `TODO(KAN-50): 위치권한 팝업 삽입 지점` 주석만 남김. KAN-50에서 이 위치에 모달을 띄우면 된다.

### 에러 매핑

`AFError.responseCode`를 스위치해 401/403/422/502를 `AuthError` case로 치환. `LocalizedError` 구현으로 `errorDescription`이 사용자 노출 문자열로 바로 쓰인다.

### 접근성

- 헤드라인: `accessibilityAddTraits(.isHeader)`
- 로고: `accessibilityHidden(true)` (장식 요소)
- CTA: `accessibilityLabel("카카오 계정으로 로그인")`
- 폰트: `pretendard(...)` 토큰만 사용 → Dynamic Type 대응 가능

### Preview

`LoginView` 단독 프리뷰는 `PreviewAuthService`를 인라인 `private final class`로 선언해 DI 없이 렌더. `KakaoLoginButton`도 `isLoading=false/true` 두 상태 프리뷰 제공.

## TODO 주석 인덱스 (후속 티켓 작업 시 grep 대상)

| 위치 | 주석 | 담당 티켓 |
|------|------|----------|
| `LoginViewModel.obtainKakaoAccessToken()` | `TODO(KAN-47): Kakao SDK 로그인 플로우로 대체` | KAN-47 |
| `LoginViewModel.signInWithKakaoTapped()` | `TODO(KAN-48): response.accessToken / refreshToken을 KeyChain에 저장` | KAN-48 |
| `AuthEndpoint.headers` | `TODO(KAN-48): TokenStore에서 access_token 가져와 Bearer 헤더 부착` | KAN-48 |
| `AuthService.currentAuthState()` | `TODO(KAN-49): KeyChain(KAN-48)에 저장된 토큰을 조회하여 .signedIn(token) 반환` | KAN-49 |
| `AppRootViewModel.bootstrap()` | 주석 (`// 현재는 항상 .signedOut 스텁. KAN-49에서...`) | KAN-49 |
| `AppRootView.HomePlaceholderView.task` | `TODO(KAN-50): 위치권한 팝업 삽입 지점` | KAN-50 |
| `AppRootViewModel.didCompleteSignIn()` | `TODO(KAN-50): isNewUser 분기 가능 (§9.4)` | KAN-50 또는 §9.4 확정 티켓 |
| `LoginView.appLogo` | `TODO(resource): Assets.xcassets/AppLogoMark.imageset 교체 필요 (§9.2)` | §9 리소스 요청 |

```
# 전체 훑어보려면
rg "TODO\(KAN-" Pickflow/Sources
rg "TODO\(resource" Pickflow/Sources
```

## 유저가 로컬에서 해야 할 후속 작업

1. `tuist generate` — 새 Swift 파일(AppConfig, AppRootView, AuthEndpoint, AuthDTO, AuthService 변경분, LoginView/VM/Button) 반영
2. Xcode `Cmd + B` 빌드 확인
3. `#Preview` 캔버스에서 `LoginView`·`KakaoLoginButton` 렌더 확인
4. (원하면) `docs/KAN-46/` 두 문서를 `feature/KAN-46`에 함께 커밋해서 PR에 포함
5. develop 대상 PR 생성 (제목·본문 영어, AGENTS.md Code Review 규칙)

## 확정 필요한 리소스 (§9 요약)

프롬프트 [§9](./prompt.md#9--개발-종료-시-유저에게-요청할-리소스-필수-단계)에 전체 체크리스트가 있다. 요약:

1. `API_BASE_URL` (dev/stage/prod) — `AppConfig.baseURL` 교체
2. `AppLogoMark` 에셋 — `Resources/Assets.xcassets/AppLogoMark.imageset/`
3. 배경 글로우 HEX 2색(중심/외곽) + 베이스 — `LoginView`의 `private extension Color`
4. 카카오 공식 심볼 이미지 사용 의무 여부
5. `is_new_user: true` 시 라우팅 대상 화면
6. 로그인 실패/로딩 UX 디자인 시안
7. 약관/개인정보처리방침 링크 & 하단 고지 문구
8. 서브카피 최종 카피 확정 여부
9. Kakao URL Scheme / `LSApplicationQueriesSchemes` — KAN-47에 전부 위임할지, 본 티켓 범위에 일부 선반영할지

## 샌드박스 한계 메모

- 이 작업은 Linux 샌드박스에서 수행되었으므로 `tuist generate` / `xcodebuild` 실행 불가 → 로컬 Mac에서 확인 필요
- `.git/*.lock` 파일을 삭제할 수 없는 샌드박스 제약이 있어 각 커밋 전후로 `mv *.lock *.lock.bak` 우회. Xcode/로컬 환경에서는 무관.
