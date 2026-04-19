# [KAN-46] 로그인(온보딩) 진입 화면 구현 — 통합 프롬프트

> 이 문서는 Claude / Codex 같은 AI 에이전트에게 KAN-46 작업을 한 번에 지시하기 위한 통합 프롬프트다.
> 아래 내용을 그대로 복사해서 에이전트 프롬프트로 사용하면 된다.

---

## 0. 역할 지시 (System / Role)

너는 `Pickflow` iOS 앱의 시니어 iOS 엔지니어다.
프로젝트의 `AGENTS.md`와 레이어 규칙(App → Feature → Common → Core)을 준수하고,
Swift 6 + SwiftUI + Swift Concurrency 스타일로 깔끔한 코드를 작성한다.
모든 코드는 컴파일 가능한 완전한 형태로 제시하고, 새 파일은 정확한 절대 경로와 함께 제공한다.

---

## 1. 티켓 개요

- **Jira Key**: KAN-46
- **Feature 브랜치**: `feature/KAN-46` (develop 기준)
- **목표**: 앱 진입 시 **로그인되지 않은 사용자**에게 노출되는 "온보딩/로그인" 화면(`LoginView`)을 구현한다.
- **핵심 CTA**: 카카오 로그인 버튼 1개 ("카카오로 시작하기")
- **진입 라우팅**: 앱 런치 시 인증 상태를 조회해, 비로그인 상태면 `LoginView`, 로그인 상태면 기존(미정) 메인 화면으로 분기한다. 메인은 이번 티켓 범위가 아니므로 `Text("Home (WIP)")` 등 임시 뷰로 둔다.
  - 현재 인증 상태 판정은 **항상 `.signedOut`** 을 리턴하는 스텁. 실제 판정(저장된 토큰 → 자동 로그인)은 **KAN-49**에서 대체되므로, `AppRootView`는 해당 지점이 쉽게 대체될 수 있도록 단일 진입점(`viewModel.currentAuthState()` 등)으로 집결시킨다.
  - 로그인 성공 직후 / 홈 최초 진입 시점에 위치권한 팝업이 삽입될 수 있도록 라우팅 훅(주석 `// TODO(KAN-50): 위치권한 팝업 삽입 지점`)만 남긴다.

---

## 2. 화면 스펙 (디자인 명세)

레퍼런스 스크린샷 요약:

- **배경**: 거의 블랙 (`#0B0B0B` 근처) + 화면 중앙에서 아래쪽으로 퍼지는 **웜 오렌지/레드 레이디얼 글로우** (`#FF6A2A` ~ `#B22A00` 톤, 불투명도 감쇠). `RadialGradient`로 구현.
- **상단 세이프에어리어**: 시스템 상태바 기본값 유지 (라이트 콘텐츠).
- **중앙 컨텐츠 (수직 중앙 정렬)**:
  1. 앱 로고 아이콘 — 약 72×72pt, 코너 16pt 라운드, 오렌지 배경. (에셋이 없으면 `Assets.xcassets`에 `AppLogoMark` 플레이스홀더 이미지셋을 생성하고 `Image("AppLogoMark")`로 사용. 에셋이 아직 없는 환경에선 `RoundedRectangle` + SF Symbol `camera.fill`로 임시 대체.)
  2. 헤드라인 텍스트(흰색, 중앙 정렬, 2줄)
     - 문구: `일상 속 반짝임,\n실패 없이 포착하세요`
     - 타이포: `.pretendard(.display(.medium))` (28/33.6, bold)
  3. 서브 카피(라이트 그레이 `#B8B8B8` 근처, 중앙 정렬, 2줄)
     - 문구: `파편화된 포토스팟 정보는 이제 그만.\n정확한 일몰 시간과 촬영 팁을 한눈에 보세요.`
     - 타이포: `.pretendard(.body(.small()))`
  4. 헤드라인–서브카피 간격 12pt, 로고–헤드라인 간격 32pt.
- **하단 CTA (세이프에어리어 하단 + 16pt)**:
  - 좌우 마진 20pt, 높이 56pt, 코너 16pt 라운드
  - 배경: 카카오 옐로우 `#FEE500`
  - 콘텐츠: 말풍선 아이콘(SF Symbol `message.fill`, 블랙) + 타이틀 `카카오로 시작하기` (블랙, `.pretendard(.body(.large(.bold)))`)
  - 탭 피드백: 누를 때 `opacity(0.85)` 정도, `Button` 기본.
- **접근성**:
  - 버튼 `accessibilityLabel("카카오 계정으로 로그인")`
  - 헤드라인/서브카피 `accessibilityAddTraits(.isHeader)` 는 헤드라인에만.
  - Dynamic Type 대응을 위해 고정 `.font(.system(size:))` 금지, 반드시 `pretendard` 토큰 사용.

---

## 3. 아키텍처 & 파일 구조

`AGENTS.md`의 레이어 규칙에 따라 다음 파일을 새로 생성/수정한다.

### 3.1. 신규 파일

```
Pickflow/Sources/Feature/Auth/
├── LoginView.swift              # SwiftUI View
├── LoginViewModel.swift         # @MainActor ObservableObject
└── Components/
    └── KakaoLoginButton.swift   # 재사용 가능한 카카오 버튼 (Feature 내부 컴포넌트)
```

- `Common/Components/`가 아닌 `Feature/Auth/Components/`에 두는 이유: 현재 시점에서 재사용 범위가 로그인 화면으로 한정되기 때문이다. 이후 다른 Feature에서도 쓰이면 그때 `Common/Components`로 승격한다.

### 3.2. 수정 파일

- `Pickflow/Sources/Core/Services/Protocols/AuthServiceProtocol.swift`
  - `func signInWithKakao(kakaoAccessToken: String) async throws -> KakaoSignInResponse` 추가 (백엔드 `POST /auth/kakao` 매핑)
  - `func refreshToken(_ refreshToken: String) async throws -> AuthToken` 추가 (`POST /auth/refresh`)
  - `func signOut() async throws` 이미 존재 → `POST /auth/logout` 매핑
  - `func currentAuthState() -> AuthState` 또는 `var isSignedIn: Bool { get async }` 추가
  - `enum AuthState { case signedOut, signedIn(AuthToken) }` 정의
  - 응답/요청 DTO는 §6의 스펙 그대로 매핑
- `Pickflow/Sources/Core/Services/AuthService.swift`
  - `NetworkManagerProtocol`을 통해 실제 네트워크 호출 구현 (카카오 SDK 호출은 제외 — `kakaoAccessToken` 인자로 받도록 경계 설정)
  - 실제 카카오 SDK 연동(= kakaoAccessToken을 얻는 단계)은 **KAN-47**. 본 티켓에서는 서비스 계층이 SDK 호출 없이 네트워크만 담당하도록 설계.
- `Pickflow/Sources/Core/Network/` 하위에 신규 `AuthEndpoint.swift` 생성 (기존 `APIEndpoint` 프로토콜 준수)
  - case: `kakaoSignIn(token: String)`, `refresh(refreshToken: String)`, `logout`, `withdraw`
- `Pickflow/Sources/App/ContentView.swift`
  - 인증 상태에 따라 `LoginView` ↔ 임시 `HomePlaceholderView`를 분기하는 루트 컨테이너로 변경.
  - `@StateObject private var viewModel = RootViewModel(...)` 또는 `@State var isSignedIn: Bool` 수준의 가벼운 게이팅. 선호: 별도 `RootViewModel` 생성 (`Feature/Auth/RootViewModel.swift`가 아닌, 간단 라우팅이므로 `App/` 아래 `AppRootView.swift`로 분리해도 됨).
- `Pickflow/Sources/App/AppContainer.swift`
  - 이미 `AuthServiceProtocol`은 등록되어 있음. 시그니처 변경에 따른 컴파일 에러만 정리.

### 3.3. ViewModel 설계 (`LoginViewModel`)

```swift
@MainActor
final class LoginViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var didSignInSucceed = false
    @Published private(set) var isNewUser = false

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func signInWithKakaoTapped() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            // 1) Kakao SDK로 kakaoAccessToken 획득 (KAN-47에서 주입받도록 설계)
            //    본 티켓에서는 서비스 호출 시그니처까지만 맞춘다.
            let kakaoAccessToken = try await obtainKakaoAccessToken() // 스텁 허용
            let response = try await authService.signInWithKakao(kakaoAccessToken: kakaoAccessToken)
            // TODO(KAN-48): response.accessToken / refreshToken을 KeyChain에 저장
            isNewUser = response.isNewUser
            didSignInSucceed = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func obtainKakaoAccessToken() async throws -> String {
        // TODO(KAN-47): Kakao SDK 연동 후 실제 토큰 반환
        throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kakao SDK 미연동 (KAN-47)"])
    }
}
```

### 3.4. View 주입 방식

- `AppContainer.shared.container.resolve(AuthServiceProtocol.self)`를 `AppRootView`에서 한 번 꺼내 `LoginViewModel`로 주입한다.
- `LoginView`는 `@StateObject var viewModel: LoginViewModel`을 외부에서 주입받는 형태(= `ProfileView`와 동일 패턴).

---

## 4. 구현 요구사항 체크리스트

작업 완료 시 아래 항목이 모두 충족되어야 한다.

- [ ] `feature/KAN-46` 브랜치에서 작업 (이미 생성되어 있음)
- [ ] 신규 파일 3개(`LoginView`, `LoginViewModel`, `KakaoLoginButton`) 생성
- [ ] `AuthServiceProtocol`에 `signInWithKakao()`, 인증 상태 조회 API 추가 + 스텁 구현
- [ ] `ContentView`(또는 `AppRootView`)에서 로그인/비로그인 분기
- [ ] 디자인 시스템 토큰(`pretendard(...)`)만 사용, 하드코딩 폰트 금지
- [ ] 컬러는 매직 넘버 대신 `Color(hex: "FEE500")` 확장 또는 `Assets.xcassets`의 Color Set 이용. 없으면 `Color(red:green:blue:)`로 정의하되 `LoginView` 상단에 `private extension Color { static let kakaoYellow = Color(red:...) ... }` 로 네임드 상수화.
- [ ] `#Preview`에서 `LoginView` 단독 프리뷰 제공 (DI 없이도 렌더되도록 `LoginViewModel`에 프리뷰용 `init` 또는 프리뷰 내 Mock `AuthServiceProtocol` 인라인 선언)
- [ ] 접근성 라벨 부여
- [ ] **파일 신규 생성 후 `tuist generate` 실행** (AGENTS.md 규칙)
- [ ] Xcode `Cmd + B` 빌드 성공 확인
- [ ] 커밋 메시지 형식: `[KAN-46] 로그인 진입 화면 UI 구현` (AGENTS.md Commit 규칙)
- [ ] 1커밋 단위로 논리적으로 분리 (UI / ViewModel·Service / 라우팅 분리 권장)

---

## 5-0. 백엔드 API 스펙 (본 티켓 관련분 발췌)

> 전체 스펙은 백엔드 명세 문서 참고. 본 티켓에서는 **Auth**만 사용.

### 공통

- **Base URL**: `https://api.example.com/v1` (실제 값은 §9에서 확인 요청 — 빌드 컨피그에 주입)
- **인증 헤더**: `Authorization: Bearer {access_token}` (🔒 필요 엔드포인트)
- **Content-Type**: `application/json`
- **JSON 키 컨벤션**: `snake_case` → Swift 모델은 `camelCase` + `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase` 적용 (또는 `CodingKeys`로 명시 매핑).

### 엔드포인트 (Auth)

| Method | Path             | 인증 | 설명            | 본 티켓 사용 |
|--------|------------------|------|-----------------|---------------|
| POST   | `/auth/kakao`    | ✗    | 카카오 로그인   | ✅            |
| POST   | `/auth/apple`    | ✗    | 애플 로그인     | ❌ (후속)     |
| POST   | `/auth/refresh`  | ✗    | 토큰 갱신       | ⚠️ 프로토콜만 |
| POST   | `/auth/logout`   | 🔒   | 로그아웃        | ⚠️ 프로토콜만 |
| DELETE | `/auth/withdraw` | 🔒   | 회원 탈퇴       | ❌ (후속)     |

### `POST /auth/kakao` 상세

**Request**

```json
{ "kakao_access_token": "string" }
```

**Response 200**

```json
{
  "access_token": "string",
  "refresh_token": "string",
  "is_new_user": true,
  "user": {
    "id": 0,
    "nickname": "string",
    "social_provider": "kakao"
  }
}
```

### Swift DTO 매핑

아래 타입을 `Core/Services/Models/` 또는 `Core/Services/Protocols/AuthServiceProtocol.swift` 근처에 선언한다.

```swift
struct KakaoSignInRequest: Encodable, Sendable {
    let kakaoAccessToken: String
}

struct KakaoSignInResponse: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let isNewUser: Bool
    let user: AuthUser
}

struct AuthUser: Decodable, Sendable {
    let id: Int64
    let nickname: String
    let socialProvider: SocialProvider
}

enum SocialProvider: String, Decodable, Sendable {
    case kakao
    case apple
}

// 기존 AuthToken은 유지하되 필드만 재확인
struct AuthToken: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
}
```

### 공통 에러 매핑

백엔드 공통 에러 → 앱 측 `AuthError` 로 변환해 사용자에게 노출.

| 서버 코드                   | HTTP | 앱 처리 |
|----------------------------|------|---------|
| `UNAUTHORIZED`             | 401  | 토큰 만료 → 재로그인 유도 |
| `FORBIDDEN`                | 403  | "권한이 없습니다" 토스트 |
| `VALIDATION_ERROR`         | 422  | "입력값을 확인해주세요" |
| `EXTERNAL_API_ERROR`       | 502  | "잠시 후 다시 시도해주세요" (카카오 SDK/서버 이슈) |
| `BOOKMARK_ALREADY_EXISTS`  | 409  | 본 티켓 범위 외 |

`LoginViewModel.errorMessage`는 위 매핑을 거친 로컬라이즈 문자열을 담는다. 에러 모델 예시:

```swift
enum AuthError: LocalizedError {
    case unauthorized
    case validation
    case external
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized: "다시 로그인해 주세요."
        case .validation: "입력값을 확인해 주세요."
        case .external: "일시적인 오류가 발생했어요. 잠시 후 다시 시도해 주세요."
        case .unknown(let error): error.localizedDescription
        }
    }
}
```

### `AuthEndpoint` 예시 (기존 `APIEndpoint` 프로토콜 준수)

```swift
enum AuthEndpoint: APIEndpoint {
    case kakaoSignIn(token: String)
    case refresh(refreshToken: String)
    case logout

    var baseURL: String { AppConfig.baseURL } // 빌드 컨피그에서 주입 (§9 요청 리소스)

    var path: String {
        switch self {
        case .kakaoSignIn: "/auth/kakao"
        case .refresh:    "/auth/refresh"
        case .logout:     "/auth/logout"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .kakaoSignIn, .refresh, .logout: .post
        }
    }

    var parameters: Parameters? {
        switch self {
        case .kakaoSignIn(let token): ["kakao_access_token": token]
        case .refresh(let rt):        ["refresh_token": rt]
        case .logout:                  nil
        }
    }

    var headers: HTTPHeaders? {
        switch self {
        case .logout:
            // TokenStore에서 access_token 가져와 Bearer 헤더 부착 (KAN-48 완료 후 활성화)
            nil
        default:
            nil
        }
    }
}
```

> 참고: 현재 `NetworkManager.request(endpoint:)`는 `Encodable` Body 전송을 위해 JSON encoding을 지정하지 않는다. `POST` JSON Body를 보내야 하므로, **필요 시 `NetworkManager`에 JSON encoding(`JSONEncoding.default`) 옵션을 얹거나 오버로드를 추가**해야 한다. 본 티켓에서 함께 수정.

---

## 5. 작업 범위 밖 (Out of Scope)

- 실제 Kakao SDK 연동 — **KAN-47**
- 토큰(KeyChain) 저장 — **KAN-48**
- 자동 로그인(스플래시에서 저장된 토큰으로 인증 상태 복구) — **KAN-49**
- 위치권한 팝업(로그인 성공 후 또는 홈 최초 진입 시 노출) — **KAN-50**
- 토큰 갱신(refresh) 로직
- 회원가입/약관 동의 화면
- 로그아웃 UI
- 서버 API 엔드포인트 실구현

`AuthService`의 **네트워크 호출 구현은 이번 티켓에서 완성**(= `/auth/kakao` 호출까지). 다만 Kakao SDK로 `kakaoAccessToken`을 얻는 부분은 `LoginViewModel.obtainKakaoAccessToken()` 스텁에 `TODO(KAN-47)`로 표시하고, 토큰 저장은 `TODO(KAN-48)`로 표시한다.

---

## 6. 예상 디렉터리 스냅샷 (작업 후)

```
Pickflow/Sources/
├── App/
│   ├── AppContainer.swift
│   ├── AppConfig.swift             # (신규) API_BASE_URL 등 환경 상수. 값은 §9에서 유저 확인.
│   ├── AppRootView.swift           # (신규 or ContentView 리네이밍)
│   ├── ContentView.swift           # AppRootView를 호출하는 얇은 래퍼로 유지 OR 삭제
│   └── PickflowApp.swift
├── Core/
│   ├── Network/
│   │   ├── APIEndpoint.swift
│   │   ├── AuthEndpoint.swift      # (신규)
│   │   └── NetworkManager.swift    # 필요 시 JSON Body encoding 지원 추가
│   └── Services/
│       ├── AuthService.swift       # 수정 (Network 실연결)
│       ├── Models/
│       │   └── AuthDTO.swift       # (신규) KakaoSignInRequest/Response, AuthUser, SocialProvider
│       └── Protocols/
│           └── AuthServiceProtocol.swift  # 수정
└── Feature/
    ├── Auth/                       # 신규
    │   ├── Components/
    │   │   └── KakaoLoginButton.swift
    │   ├── LoginView.swift
    │   └── LoginViewModel.swift
    └── Profile/
```

---

## 7. 에이전트 응답 포맷

다음 순서로 응답한다:

1. **변경 요약** — 어떤 파일을 만들고 왜 그렇게 나눴는지 2–3문장.
2. **파일별 전체 코드** — 각 파일마다 절대 경로를 제목으로, 그 아래에 전체 소스를 ```swift 블록으로.
3. **AuthServiceProtocol / AuthService / AppContainer / ContentView diff** — 기존 파일 수정분은 diff 또는 변경된 전체 파일로.
4. **실행 명령** — `tuist generate`, 빌드 명령, 커밋 명령을 순서대로.
5. **후속 티켓 연결** — Kakao SDK 실연동(**KAN-47**), 토큰 KeyChain 저장(**KAN-48**), 자동 로그인(**KAN-49**), 위치권한 팝업(**KAN-50**).
6. **🔔 유저에게 리소스 요청 (§9 참고)** — 개발 마지막 단계에 반드시 포함. 누락된 디자인/환경값/자산을 체크리스트로 나열하고, 각 항목마다 "어디에 어떤 형식으로 넣어달라"는 요구까지 명시.

---

## 8. 프로젝트 컨텍스트 요약 (에이전트가 내재화할 것)

- 프로젝트명: **Pickflow** (iOS 26+, SwiftUI, Swift 6, Tuist, SPM, Alamofire, Swinject)
- 아키텍처: `App → Feature → Common → Core` / Core는 Common 모름
- DI: `AppContainer.shared.container` 에서 `AuthServiceProtocol` 등 서비스 해결
- 디자인 시스템: Pretendard 토큰 (`pretendard(.display(.medium))` 등)
- 커밋 규칙: `[KAN-46] ...`
- 신규 Service 추가 시 `AppContainer.registerDependencies()` 등록 필수 (이번엔 신규 Service 없음, 프로토콜 확장만)
- Swift 파일 추가/삭제 시 `tuist generate` 필수

---

## 9. 🔔 개발 종료 시 유저에게 요청할 리소스 (필수 단계)

**에이전트는 코드 작성이 끝난 직후, 응답의 마지막 섹션에서 아래 항목 중 누락/확정되지 않은 것을 모두 체크리스트로 나열해 유저에게 제공을 요청해야 한다.** 에이전트가 임의로 값을 지어내지 말 것. 플레이스홀더로 커밋된 경우에도 "이 값은 유저 확인 필요"로 명시.

### 9.1. 환경 / 빌드 설정

- [ ] **`API_BASE_URL`** — 실제 서버 Base URL (예: `https://api.pickflow.kr/v1`). 현재 명세는 예시값(`https://api.example.com/v1`). 환경별(dev/stage/prod) 값 모두 요청.
- [ ] **Kakao Native App Key** — `Info.plist`의 `KAKAO_NATIVE_APP_KEY`에 주입. (실제 SDK 연동 티켓에서 사용되지만, URL Scheme(`kakao{APP_KEY}`) / LSApplicationQueriesSchemes 등록을 이번 티켓에서 선반영할지 여부 확인)
- [ ] **URL Scheme / Info.plist 엔트리** — 위 키 기반 `kakao{appkey}` URL Scheme, `LSApplicationQueriesSchemes`(`kakaokompassauth`, `kakaolink`) 추가 여부.

### 9.2. 디자인 자산

- [ ] **앱 로고 이미지** (`AppLogoMark`) — 1x / 2x / 3x PNG 또는 PDF(Single Scale). `Resources/Assets.xcassets/AppLogoMark.imageset/`에 드랍. 현재는 SF Symbol 플레이스홀더 사용 중.
- [ ] **배경 글로우 컬러 팔레트** — 중앙 글로우 중심색 / 외곽색 HEX 확정값. 현재 구현은 추정치(`#FF6A2A` → `#0B0B0B`).
- [ ] **카카오 버튼 컬러 & 아이콘** — 공식 카카오 옐로우(`#FEE500`) 외에, 카카오 공식 심볼 이미지 사용 의무 여부(카카오 가이드라인 준수). 현재는 SF Symbol `message.fill`로 대체.
- [ ] **헤드라인 / 서브카피 최종 카피** — 현재 스펙은 디자인 시안 문구 그대로. 확정 여부.

### 9.3. 법적 / 정책

- [ ] **이용약관 / 개인정보처리방침 링크** — 로그인 버튼 하단에 "계속하면 약관 및 개인정보처리방침에 동의합니다" 같은 문구 추가 여부. 현재 시안에는 없음.
- [ ] **연령 확인 / 마케팅 수신 동의** 필요 여부 (서비스 정책에 따라).

### 9.4. 기능 플로우

- [ ] **`is_new_user: true`** 응답 시 이동할 화면 — 닉네임 설정 / 온보딩 튜토리얼 / 바로 홈? 현재는 둘 다 홈으로 보냄.
- [ ] **로그인 실패 시 UX** — 토스트? 알림창? 인라인 에러 텍스트? 디자인 시안 필요.
- [ ] **로딩 중 UX** — 버튼 스피너 / 전체 화면 딤드 여부.

### 9.5. 연동 티켓 (확정)

- ✅ **Kakao iOS SDK 연동** — **KAN-47** (`LoginViewModel.obtainKakaoAccessToken()` 스텁 주석에 이미 반영)
- ✅ **토큰 저장(KeyChain)** — **KAN-48** (`LoginViewModel` 내 `TODO(KAN-48)` 주석, `AuthEndpoint.logout`의 Bearer 헤더 활성화 조건에 반영)
- ✅ **자동 로그인(스플래시에서 토큰 체크)** — **KAN-49** (`AppRootView`의 초기 인증 상태 판정 로직이 이 티켓에서 실구현으로 대체됨)
- ✅ **위치권한 팝업 기능** — **KAN-50** (로그인 성공 직후 홈 진입 전 / 또는 최초 진입 시 노출. 본 티켓은 라우팅 훅만 마련하고 실제 팝업은 KAN-50에서 구현)

### 요청 예시 (에이전트가 응답에 포함할 문구)

> ### 🙋 확정 필요한 리소스
>
> 구현은 위와 같이 완료했습니다. 아래 항목은 임의로 정할 수 없어 플레이스홀더로 두었어요. 다음 값을 전달해 주시면 반영하겠습니다.
>
> 1. 실제 `API_BASE_URL` (dev/stage/prod)
> 2. `AppLogoMark` 에셋 (1x/2x/3x PNG 또는 PDF)
> 3. 배경 글로우 HEX 2색(중심/외곽)
> 4. 카카오 공식 심볼 이미지 사용 여부 (가이드라인 준수 확인)
> 5. `is_new_user: true` 시 라우팅 대상 화면
> 6. 로그인 실패/로딩 시 UX 시안
> 7. 약관·개인정보처리방침 링크 & 하단 고지 문구
> 8. (참고) 후속 티켓은 모두 확정됨 — Kakao SDK 연동: **KAN-47**, KeyChain 저장: **KAN-48**, 자동 로그인: **KAN-49**, 위치권한 팝업: **KAN-50**. 본 티켓의 스텁/주석/라우팅 훅이 이 티켓들과 정확히 연결되어 있는지 확인 부탁드려요.

---

**끝. 위 명세 그대로 구현 시작. 마지막에 §9의 리소스 요청을 빼먹지 말 것.**
