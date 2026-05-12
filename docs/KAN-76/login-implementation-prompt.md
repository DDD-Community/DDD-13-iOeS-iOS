# [KAN-76] 로그인 화면 구현 통합 프롬프트

> **이 프롬프트의 사용법**: `screen-tdd-prompt` 스킬이 템플릿을 복제·치환해서 저장한 결과물.
>
> **방법론은 여기 없다.** TDD 단계별 디테일은 단계 진입 시 리프 문서를 읽는다:
> - Phase A: `docs/phases/phase-a-viewmodel-tdd.md`
> - Phase B: `docs/phases/phase-b-ui-cases.md`
> - Phase C: `docs/phases/phase-c-snapshot.md`
>
> 본 문서는 **이 화면에만 해당하는 사실**(스코프, API, 정책, 에셋, 컴포넌트 매핑)을 담는다.

---

## 0. 작업 컨텍스트 (선결 정보)

**브랜치**: `feature/KAN-76` (워크트리 `.claude/worktrees/feature+KAN-76/`에서 작업)
**티켓**: <!-- TODO: Atlassian 인증 후 Jira URL 채우기 (https://dddios1.atlassian.net/browse/KAN-76) -->
**전체 화면 Figma**: `https://www.figma.com/design/LyduUVMjsQi0qyUsENriR5/?node-id=1067-5051`

**프로젝트 가정 (재탐색 불필요)**:
- SwiftUI + MVVM, Tuist 매니페스트(`Project.swift`)
- 외부 의존성: Alamofire, Swinject, KakaoSDK*, nMapsMap, FirebaseMessaging
- DI: `AppContainer.shared.registerDependencies()` → `getXxxService()` MainActor 헬퍼
- 디자인 시스템: `Resources/DesignSystem/Colors.xcassets` → `UIAsset.Colors.*` 자동 생성, `Common/DesignSystem/Fonts/PickflowTypography.swift`의 `.pretendard(...)` 토큰
- 테스트 타겟 `PickflowTests` 존재. 신규 테스트는 거기에 추가
- `SWIFT_STRICT_CONCURRENCY: complete` — 모든 신규 타입 `Sendable`/`@MainActor` 명시
- 선례: KAN-51(`Feature/SpotDetail/*`), KAN-47(`Feature/Auth/*` 카카오 로그인)

**KAN-76 이전 상태 (그대로 두고 위에 얹는다)**:
- `Feature/Auth/LoginView.swift` — 다크 배경 + radial blur glow, `KakaoLoginButton` 단일 CTA
- `Feature/Auth/LoginViewModel.swift` — `signInWithKakaoTapped()` async 인텐트 1개
- `Feature/Auth/Components/KakaoLoginButton.swift` — `cornerRadius: 16`, "카카오로 시작하기"
- `Core/Services/AuthService.swift` + `AuthEndpoint.kakaoSignIn(...)` — `POST /auth/kakao` 구현 완료
- `Core/Services/Models/AuthDTO.swift` — `SocialProvider.apple` 케이스는 이미 정의됨

**KAN-76 미설정 (추가 작업 필요)**:
- `Sign in with Apple` capability — `Project.swift`에 `entitlements:` 추가, `Pickflow.entitlements` 신규
- `AuthenticationServices.framework` — 시스템 프레임워크 (외부 의존성 추가 불필요)
- `swift-snapshot-testing` — Phase C 진입 전 Tuist `Package.swift` + `.external(.snapshotTesting)` 추가

---

## 1. 스코프

**구현 범위**:
- Apple 로그인 기능 — `AppleAuthProvider` (AuthenticationServices), `AuthService.signInWithApple(identityToken:nonce:)`, `AuthEndpoint.appleSignIn`, `LoginViewModel.signInWithAppleTapped()`
- 로그인 화면 UI 리뉴얼 — Figma `1067:5051` 기준
  - 배경: radial blur glow → **linear gradient** (warm orange → dark)
  - 상단 좌측 `PICKFLOW` 로고 (status bar 아래)
  - 중앙 로고: 60×60 white rounded-rect + `ic_flare` 40×40
  - 헤드라인 카피 유지, 버튼 영역 위로 이동
  - 카카오 버튼: cornerRadius 16→**8**, 카피 "카카오로 시작하기"→**"카카오로 로그인"**
  - Apple 버튼 신규 — 흰 배경, `ic_apple` 24, "Apple로 로그인"
  - "비회원으로 시작하기" 텍스트 링크 (15pt, underline, `#b1b8be`)

**범위 밖**:
- 자동 로그인(`currentAuthState()` 실구현) — KAN-49로 분리
- 비회원 모드 백엔드 연동 — 본 티켓에선 텍스트 링크 + tap 핸들러 셸까지만, 실제 진입 흐름은 별도 합의 후 (`§13` 논의 포인트)
- Apple Services ID/Team ID/Key ID/EC Private Key는 백엔드 보관. iOS는 `identityToken`(JWT)만 보낸다
- 콜백 URL은 백엔드 검증 단계에서만 사용. iOS 네이티브 flow는 콜백 URL 불필요

---

## 2. 핵심 정책 결정 (사용자 확정)

| # | 항목 | 결정 |
|---|---|---|
| 1 | Apple 인증 흐름 | `ASAuthorizationAppleIDProvider` 네이티브 사용. 웹 OAuth 콜백 X |
| 2 | iOS → 백엔드 전송 | `identityToken`(Data → UTF-8 String), `nonce`(평문) |
| 3 | nonce 생성 | `SHA256(rawNonce)` → request, `rawNonce`는 백엔드에 평문 동봉(또는 `§13`로 합의) |
| 4 | 토큰 저장 | 기존 `KeychainTokenStore` 재사용 (카카오와 동일) |
| 5 | 응답 모델 | `KakaoSignInResponse` 형태 그대로 미러링 — `AppleSignInResponse` 신규 (구조 동일) |
| 6 | 로그인 실패 UX | 기존 `errorAlertBinding` 패턴 재사용. `AppleAuthError`는 `AuthError`로 매핑 |
| 7 | 비회원 진입 | 본 티켓에선 `viewModel.continueAsGuestTapped()` 셸만. 실제 라우팅은 `§13`. 비회원 백엔드/세션 처리는 KAN-XX |
| 8 | 카카오 버튼 카피 변경 | "카카오로 시작하기" → "카카오로 로그인" (Figma 텍스트 일치) |
| 9 | 카카오 버튼 cornerRadius | 16 → **8** (Figma 토큰 일치) |

---

## 3. API 매핑

| UI 동작 | Endpoint | 비고 |
|---|---|---|
| Apple 버튼 탭 | `POST /auth/apple` <!-- TODO: 실제 path 백엔드와 확정 --> | body: `{ "identity_token": "<JWT>", "nonce": "<raw>" }` <!-- TODO: 키 네이밍 백엔드와 확정 --> |
| 카카오 버튼 탭 | `POST /auth/kakao` | 기존 그대로. 변경 없음 |
| 토큰 갱신 | `POST /auth/refresh` | 기존 그대로 |

응답 형태는 카카오와 동일: `accessToken`, `refreshToken`, `isNewUser`, `user: AuthUser`. `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase` 전역 적용.

---

## 4. 신규/수정 파일 목록

**신규**
```
Pickflow/Sources/
  Core/Services/
    AppleAuthProvider.swift                    ← AuthenticationServices 래퍼
    Protocols/AppleAuthProviderProtocol.swift
  Feature/Auth/Components/
    AppleLoginButton.swift                     ← 흰 배경, ic_apple, "Apple로 로그인"
    PickflowLogoMark.swift                     ← 상단 좌측 PICKFLOW (선택, 인라인 처리도 가능)

Pickflow/Resources/
  Pickflow.entitlements                        ← com.apple.developer.applesignin
  Assets.xcassets/
    ic_apple.imageset/                         ← Figma 1067:5061 ic_apple export
    ic_flare.imageset/                         ← Figma 1067:5055 (이미 ?? 상태로 git status에 있음 — 검수)
    AppLogoMark.imageset/ 또는 ic_flare 재사용  ← §9.2 결정

PickflowTests/
  AppleAuthProviderTests.swift                 ← 선택 (provider 단위 테스트)
  LoginViewModelTests.swift                    ← Phase A 신규
  LoginViewSnapshotTests.swift                 ← Phase C 신규
  Helpers/AuthTestDoubles.swift                ← 신규 또는 기존 SpotDetailTestDoubles 패턴 미러링

docs/KAN-76/
  login-implementation-prompt.md               ← 본 문서
  ui-test-cases.md                             ← Phase B에서 채움
  login-discussion.md                          ← §13 후속 합의
```

**수정**
- `Pickflow/Sources/App/AppContainer.swift` — `AppleAuthProviderProtocol` 등록
- `Pickflow/Sources/App/PickflowApp.swift` — (현재 `M` 상태) 변경 영향 검토
- `Pickflow/Sources/Core/Network/AuthEndpoint.swift` — `case appleSignIn(identityToken: String, nonce: String)` 추가
- `Pickflow/Sources/Core/Services/AuthService.swift` — `signInWithApple(...)` 추가
- `Pickflow/Sources/Core/Services/Protocols/AuthServiceProtocol.swift` — 동일 메서드 시그니처
- `Pickflow/Sources/Core/Services/Models/AuthDTO.swift` — `AppleSignInRequest`, `AppleSignInResponse` 추가
- `Pickflow/Sources/Feature/Auth/LoginView.swift` — 배경/로고/PICKFLOW 헤더/버튼 스택 리뉴얼
- `Pickflow/Sources/Feature/Auth/LoginViewModel.swift` — `signInWithAppleTapped()`, `continueAsGuestTapped()` 추가
- `Pickflow/Sources/Feature/Auth/Components/KakaoLoginButton.swift` — cornerRadius 8, 카피 "카카오로 로그인"
- `Project.swift` — `entitlements: "Pickflow/Resources/Pickflow.entitlements"`, Phase C 진입 시 `.external(.snapshotTesting)` 테스트 타겟에 추가
- `Tuist/Package.swift` (또는 동등 위치) — `pointfreeco/swift-snapshot-testing` 등록

---

## 5. 모델 정의 가이드

```swift
// AuthDTO.swift 추가분
struct AppleSignInRequest: Encodable, Sendable {
    let identityToken: String
    let nonce: String

    enum CodingKeys: String, CodingKey {
        case identityToken = "identity_token"
        case nonce
    }
}

struct AppleSignInResponse: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let isNewUser: Bool
    let user: AuthUser
}

// AppleAuthProvider.swift
struct AppleCredential: Sendable {
    let identityToken: String
    let nonce: String  // raw nonce — ASAuthorizationAppleIDRequest.nonce에는 sha256 해시본이 들어간다
}

enum AppleAuthError: LocalizedError {
    case cancelled
    case invalidToken
    case underlying(Error)
    // errorDescription은 KakaoAuthError 패턴 미러링
}
```

JSONDecoder는 `convertFromSnakeCase` 전역 적용 → 모델엔 CodingKeys 박지 않는다 (단, Encodable Request는 명시 필요).

---

## 6. ViewModel 시그니처

```swift
@MainActor
final class LoginViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var didSignInSucceed = false
    @Published private(set) var didRequestGuestEntry = false  // 신규

    private let authService: AuthServiceProtocol
    private let kakaoAuthProvider: KakaoAuthProviderProtocol
    private let appleAuthProvider: AppleAuthProviderProtocol  // 신규
    private let tokenStore: TokenStoreProtocol

    init(
        authService: AuthServiceProtocol,
        kakaoAuthProvider: KakaoAuthProviderProtocol,
        appleAuthProvider: AppleAuthProviderProtocol,  // 신규
        tokenStore: TokenStoreProtocol
    )

    func signInWithKakaoTapped() async      // 기존
    func signInWithAppleTapped() async      // 신규
    func continueAsGuestTapped()            // 신규 셸 — didRequestGuestEntry = true
}
```

DI: `AppContainer.registerDependencies()`에 `AppleAuthProvider` 등록. `KakaoAuthProvider`와 동일 scope.

---

## 7. 외부 앱 / 시스템 연동

**Sign in with Apple (네이티브)**:
- `AuthenticationServices.framework` 사용. 외부 의존성 추가 불필요
- `Pickflow.entitlements`에 `com.apple.developer.applesignin = ["Default"]`
- `Project.swift` 메인 타겟 `entitlements: "Pickflow/Resources/Pickflow.entitlements"`
- Apple Developer 콘솔에서 App ID에 "Sign In with Apple" capability 활성화 (수동 설정, 빌드 전)
- **콜백 URL 불필요** — 네이티브 flow는 백엔드↔Apple 검증 단계에서만 콜백 URL이 필요하고, 이는 백엔드 책임

**백엔드 공유 정보 (iOS는 직접 안 씀, 참고만)**:
- Services ID, Team ID, Key ID, EC Private Key (PKCS8 PEM) — 백엔드가 Apple 서버에 client_secret JWT 서명할 때 사용

---

## 8. 화면별 정밀 사양

**배경 (Figma 1067:5052)**:
- `LinearGradient(stops: [(rgb(181,127,0), 0%), (rgb(188,59,0), 20%), (rgb(15,23,40), 50%), (rgb(19,20,22), 100%)], start: .top, end: .bottom)`
- 391×845, 화면 중앙 정렬 (safe area ignore)
- **현 코드의 radial blur glow는 제거**

**상단 헤더 (Figma 1067:5066~5068)**:
- `PICKFLOW` 로고 — 140×32, 좌측 `padding(16)`, 상단 `padding(8)` (status bar 아래)
- 우측 `거리순 + expand_more` 영역은 `opacity-0` 상태 → **렌더하지 않음** (placeholder)

**중앙 컨텐츠 스택 (Figma 1067:5053)**:
- 295×238, vCenter (top: 50% - 140)
- spacing: 24
- 로고 60×60 (white rounded 12) + ic_flare 40×40
- 헤드라인 34pt Bold, line-height 1.2, letter-spacing -0.2
- 서브헤드 17pt Regular, line-height 1.4

**하단 CTA 스택 (Figma 1067:5058)**:
- 358×161, bottom: 66, hCenter
- 버튼 stack spacing: 12 (button group 내부), 16 (group ↔ guest link)
- 버튼 56pt 높이, cornerRadius 8

---

## 9. 디자인 시스템 추가 — **에셋 입력 매트릭스 (Gate 4)**

> **이 두 매트릭스가 모두 채워진 다음에야 §10 Phase A를 시작한다.** 미채움 상태로 Phase A 진입 금지.

### 9.1 컬러 매트릭스

| 토큰명 | Figma node | hex (Light=Dark) | 용도 |
|---|---|---|---|
| `loginGradientStop0` | 1067:5052 | `#B57F00` | 배경 그라디언트 0% |
| `loginGradientStop20` | 1067:5052 | `#BC3B00` | 배경 그라디언트 20% |
| `loginGradientStop50` | 1067:5052 | `#0F1728` | 배경 그라디언트 50% |
| `loginGradientStop100` | 1067:5052 | `#131416` | 배경 그라디언트 100% (= 기존 `gray95`) |
| `kakaoButtonYellow` | 1067:5060 | `#FEE404` | 카카오 버튼 배경 (현 코드 `#FEE500` → 정정) |
| `appleButtonWhite` | 1067:5061 | `#FFFFFF` | Apple 버튼 배경 (= `gray0`) |
| `appleButtonLabel` | I1067:5061;926:19096 | `#1E2124` | Apple 버튼 텍스트 (= `gray90`) |
| `guestLinkLabel` | 1067:5062 | `#B1B8BE` | "비회원으로 시작하기" 텍스트 |

> 그라디언트는 단일 토큰화보다 4-stop을 그대로 인라인 정의하는 게 명료. `Resources/DesignSystem/Colors.xcassets`에 추가가 필요한 건 `gray95`/`gray90`/`gray0`이 이미 있으면 신규 0건. <!-- TODO: 기존 토큰 hex 매칭 확인 후 신규 추가 여부 결정 -->

추가 후 `tuist generate` 시 `UIAsset.Colors.*`에 자동 추가됨.

### 9.2 아이콘/이미지 매트릭스

| 에셋명 | Figma node | export 포맷 | 사이즈 (1x/2x/3x) | 용도 |
|---|---|---|---|---|
| `ic_flare` | I1067:5055;185:1280 | SVG → PDF (vector) | template, 40pt | 중앙 로고 마크 안의 별 아이콘 |
| `ic_kakao` | I1067:5060;926:19061 | SVG → PDF | template, 24pt | 카카오 버튼 안 메시지 아이콘 |
| `ic_apple` | I1067:5061;926:19095 | SVG → PDF | template, 24pt | Apple 버튼 안 사과 로고 |
| `pickflow_wordmark` | 1067:5068 | SVG → PDF | template, 140×32 | 상단 PICKFLOW 로고 |

> git status에 `?? ic_flare.imageset/`이 이미 있음 — KAN-56에서 추가됐을 가능성. 검수 후 그대로 사용 가능.

`Pickflow/Resources/Assets.xcassets/<name>.imageset/`에 등록.

### 9.3 타이포 매핑 (사용한 토큰만)

| 사용처 | 토큰 | 폴백 |
|---|---|---|
| 헤드라인 "일상 속 반짝임..." | `.pretendard(.display(.medium))` (34pt Bold, lh 1.2) | 현 코드 그대로 |
| 서브헤드 "파편화된..." | `.pretendard(.body(.large()))` (17pt Regular, lh 1.4) | 현 코드는 `.body(.small())` → **변경 필요** |
| 카카오 버튼 라벨 | `.pretendard(.body(.large(.bold)))` 또는 SemiBold 토큰 | 현 코드 그대로 (SemiBold가 더 정확) |
| Apple 버튼 라벨 | 동일 | 신규 |
| 비회원 링크 | `.pretendard(.body(.medium()))` (15pt Regular, underline) | 신규 |

> `pretendard` SemiBold 토큰 명세 확인 — 17pt SemiBold + lh 1.4가 표준 토큰에 있는지 확인하고 없으면 추가. <!-- TODO -->

> 매트릭스 채움 자가 점검:
> - [ ] §9.1, §9.2가 비어 있지 않다
> - [ ] 각 행이 실제 Figma 노드를 가리키고 hex/사이즈가 명시되어 있다
> - [ ] 누락된 토큰이 `<!-- TODO -->`가 아니라 실제 값으로 채워졌다 (현재 9.1/9.3 일부 TODO 잔존)

위 3개 모두 통과해야 Phase A 진입.

---

## 10. TDD A→B→C 오케스트레이션 (Gate 1)

> **A → B → C는 직렬이다. 단계 건너뛰기·병렬화·역순 모두 금지.**

```
§9 에셋 매트릭스 (Gate 4)
        ↓
Phase A — ViewModel TDD (Gate 1A)
  · 진입: §3, §6, §9 모두 확정 — 특히 Apple endpoint path/body가 TODO에서 풀린 상태
  · 작업: signInWithAppleTapped/Kakao/continueAsGuest 인텐트별 RED → GREEN, SwiftUI 뷰 0줄
  · 종료: LoginViewModelTests 100% green, 뷰 파일 0줄 변경
  · 가이드: docs/phases/phase-a-viewmodel-tdd.md ← Phase A 들어갈 때 읽기
        ↓
Phase B — ui-test-cases.md (Gate 1B + Gate 2)
  · 진입: Phase A 종료 조건 통과
  · 작업: docs/KAN-76/ui-test-cases.md 8컬럼 표 작성
  · 종료: TODO 0개, 행마다 스냅샷 파일명 결정. 최소 커버리지: 기본/로딩(애플)/로딩(카카오)/에러 alert
  · 가이드: docs/phases/phase-b-ui-cases.md ← Phase B 들어갈 때 읽기
        ↓
Phase C — Snapshot + UI (Gate 1C + Gate 3)
  · 진입: Phase B 종료 조건 통과 + swift-snapshot-testing 의존성 추가
  · 작업: 스냅샷 케이스 RED → SwiftUI 뷰 리뉴얼 → GREEN, §11 Figma 비교 루프
  · 종료: 매트릭스 전 케이스 green, Figma 노드별 비교 1회
  · 가이드: docs/phases/phase-c-snapshot.md ← Phase C 들어갈 때 읽기
```

> 각 Phase에 **들어갈 때** 해당 리프 문서를 read한다. 미리 다 읽어두지 않는다.

---

## 11. UI 검증 루프 (Figma 노드별 비교, Phase C 마무리)

| 컴포넌트 | Figma node-id | 확인 항목 |
|---|---|---|
| 루트 프레임 | `1067:5051` | 390×844 safe area, 배경 그라디언트 4-stop 일치 |
| 배경 그라디언트 | `1067:5052` | linear, 0%/20%/50%/100% 색 일치 |
| 상단 PICKFLOW 헤더 | `1067:5067`, `1067:5068` | 좌측 16/8 padding, 우측 영역 미렌더 |
| 중앙 스택 | `1067:5053` | 가운데 정렬, top: 50%-140, gap 24 |
| 로고 마크 | `1067:5054`, `1067:5055` | 60×60 white rounded 12, ic_flare 40 |
| 헤드라인 | `1067:5056` | 34pt Bold, lh 1.2, 2 line center |
| 서브헤드 | `1067:5057` | 17pt Regular, lh 1.4, gray20 |
| 하단 CTA 스택 | `1067:5058`, `1067:5059` | bottom 66, gap 12/16 |
| 카카오 버튼 | `1067:5060` | bg #FEE404, cornerRadius 8, 56h, "카카오로 로그인" |
| Apple 버튼 | `1067:5061` | bg white, cornerRadius 8, 56h, "Apple로 로그인" |
| 비회원 링크 | `1067:5062` | 15pt Regular underline #B1B8BE |

각 노드 조회: `mcp__claude_ai_Figma__get_design_context` / `get_screenshot` (fileKey `LyduUVMjsQi0qyUsENriR5`).

---

## 12. 디버그 진입점

```swift
// AppRootView 내부 또는 PickflowApp 디버그 루트에 임시 박스
@State private var isLoginPresented = false

Button("로그인 화면 열기") { isLoginPresented = true }
    .fullScreenCover(isPresented: $isLoginPresented) {
        LoginView(viewModel: LoginViewModel(
            authService: getAuthService(),
            kakaoAuthProvider: AppContainer.shared.container.resolve(KakaoAuthProviderProtocol.self)!,
            appleAuthProvider: AppContainer.shared.container.resolve(AppleAuthProviderProtocol.self)!,
            tokenStore: AppContainer.shared.container.resolve(TokenStoreProtocol.self)!
        ))
    }
```

시뮬레이터에서 Apple 버튼 동작 확인 시 **실기기/Apple Developer 계정 로그인된 시뮬** 필요. 미로그인 시뮬에서는 `ASAuthorizationError.unknown` 등 발생 가능 — 정상.

---

## 13. 논의 포인트 MD

`docs/KAN-76/login-discussion.md` 별도 작성. 합의 필요 항목:

1. **백엔드 Apple endpoint 스펙** — path (`/auth/apple` 추정), request body 키 네이밍 (`identity_token` vs `identityToken`), nonce 동봉 방식 (raw vs hashed)
2. **응답 모델 통합 여부** — `KakaoSignInResponse`/`AppleSignInResponse` 그대로 둘지 vs `SocialSignInResponse`로 통합 리팩터 (KAN-76 스코프 안/밖?)
3. **비회원 진입 흐름** — 텍스트 링크 탭 시 어디로? 게스트 토큰 발급? Spot 탐색만 가능한 별도 라우팅?
4. **카카오 버튼 카피 변경 PR 분리 여부** — Figma 일치 변경이 디자인 합의 사항인지 확인. 분리한다면 KAN-76에서 빠짐
5. **`AppLogoMark` vs `ic_flare`** — 현 LoginView의 `AppLogoMark` 폴백을 `ic_flare`로 일원화할지

---

## 14. 마감 체크리스트

각 Phase 리프 문서에 단계별 종료 조건이 있다. 여기서는 **PR 머지 직전 한 번 더 확인할 게이트만** 모은다.

**게이트 통과**
- [ ] Gate 1 (TDD A→B→C 직렬): 단계 순서 위반 없음
- [ ] Gate 2 (`docs/KAN-76/ui-test-cases.md`): TODO 0개, 8컬럼 채움
- [ ] Gate 3 (swift-snapshot-testing): 매트릭스 전 케이스 green, `__Snapshots__/` PR 첨부, record 블라인드 덮어쓰기 0건
- [ ] Gate 4 (에셋 매트릭스): §9.1·§9.2 채움 후에 Phase A 시작했음

**일반**
- [ ] `SWIFT_STRICT_CONCURRENCY: complete` 빌드 경고/에러 0
- [ ] §11 Figma 비교 루프 1회 이상
- [ ] §12 디버그 진입점에서 시뮬레이터 동작 확인 (Apple 로그인은 실기기 권장)
- [ ] `Pickflow.entitlements` 포함, Apple Developer 콘솔 capability 확인
- [ ] `docs/KAN-76/login-discussion.md` 작성

> 단계 내부 체크리스트(예: "Phase A 종료 조건")는 해당 리프 문서를 본다.

---

## 15. 작업 순서 요약

```
0. §0~§8 합의 → §9 에셋 매트릭스 채움 (Gate 4)
   · 특히 §3 Apple endpoint TODO와 §13 #1 합의 선행
        ↓
1. docs/phases/phase-a-viewmodel-tdd.md 읽기 → Phase A 수행 (Gate 1A)
   · LoginViewModelTests 신규: signInWithAppleTapped 성공/취소/실패, continueAsGuestTapped
   · AppleAuthProviderTests (선택): provider mock 패턴
        ↓
2. docs/phases/phase-b-ui-cases.md 읽기 → Phase B 수행 (Gate 1B + 2)
   · ui-test-cases.md: 기본 / 카카오 로딩 / 애플 로딩 / 에러 alert / (선택) iPad·Dynamic Type
        ↓
3. swift-snapshot-testing 의존성 추가 → docs/phases/phase-c-snapshot.md 읽기 → Phase C 수행
   · LoginViewSnapshotTests RED → LoginView 리뉴얼 + AppleLoginButton + KakaoLoginButton 수정
   · §11 Figma 노드별 비교 루프
        ↓
4. §12 디버그 검증 (시뮬+실기기) → §13 login-discussion.md → §14 통과 → PR
```

> 순서를 어겼다면 PR 본문에 어디서 거꾸로 갔는지 명시.
