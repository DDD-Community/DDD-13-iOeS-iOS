# [KAN-54] My Profile 화면 구현 통합 프롬프트

> **이 프롬프트의 사용법**: `screen-tdd-prompt` 스킬이 이 템플릿을 복제·치환해서 저장한 결과물이다.
>
> **방법론은 여기 없다.** TDD 단계별 디테일은 단계 진입 시 리프 문서를 읽는다:
> - Phase A: `docs/phases/phase-a-viewmodel-tdd.md`
> - Phase B: `docs/phases/phase-b-ui-cases.md`
> - Phase C: `docs/phases/phase-c-snapshot.md`
>
> 본 문서는 **My Profile 화면에만 해당하는 사실**(스코프, API, 정책, 에셋, 컴포넌트 매핑)을 담는다.

---

## 0. 작업 컨텍스트 (선결 정보)

**브랜치**: `feature/KAN-54` (develop에서 분기, 최신 develop fast-forward 머지 완료 — `UserEndpoint.swift` 포함)
**티켓**: https://dddios1.atlassian.net/browse/KAN-54
**Figma 파일**: `https://www.figma.com/design/LyduUVMjsQi0qyUsENriR5/DDD-design`

**프로젝트 가정 (재탐색 불필요)**:
- SwiftUI + MVVM, Tuist 매니페스트(`Project.swift`)
- 외부 의존성: Alamofire, Swinject, KakaoSDK*, nMapsMap, FirebaseMessaging
- DI: `AppContainer.shared.registerDependencies()` → `getXxxService()` MainActor 헬퍼
- 디자인 시스템: `Resources/DesignSystem/Colors.xcassets` → `UIAsset.Colors.*` 자동 생성, `Common/DesignSystem/Fonts/PickflowTypography.swift`의 `.pretendard(...)` 토큰
- 테스트 타겟 `PickflowTests` 존재
- `SWIFT_STRICT_CONCURRENCY: complete` — 모든 신규 타입 `Sendable`/`@MainActor` 명시
- 선례: KAN-51 (`Feature/SpotDetail/*`), `docs/KAN-51/spot-detail-implementation-prompt.md`

**기존 스켈레톤 (덮어쓰기 대상)**:
- `Feature/Profile/ProfileView.swift`, `ProfileViewModel.swift` — placeholder. 본 티켓에서 실제 구현으로 대체.
- `Core/Services/UserService.swift::fetchCurrentUser()` — `fatalError("Not implemented")`. 본 티켓에서 구현.
- `Core/Services/Protocols/UserServiceProtocol.swift::User` — `{id, name, email}` 최소형. Figma 디자인 확인 후 필드 확장 가능.

---

## 1. 스코프

**구현 범위**:
- 비로그인 상태 My Profile 탭 화면 (Figma `1032:4848`)
- 로그인 상태 My Profile 화면 (Figma `1014:24892`)
- 계정관리 화면 (Figma `1014:25012`) — 프로필 정보 표시 + 닉네임/프로필 이미지 편집 + 연결된 소셜 표시 + 로그아웃/탈퇴 진입
- 로그아웃 확인 팝업 (Figma `1067:5258`)
- 회원탈퇴 플로우 (Figma `1067:5440`, `1067:5499`, `1067:5553`, `1063:5115`)
- 위 화면들을 연결하는 내비게이션
- `UserEndpoint`에 `GET /v1/users/me` 케이스 추가
- `UserService.fetchCurrentUser()` 실제 구현 + `deleteAccount` + `updateProfile` 호출 래퍼
- `User` 모델 필드 확장 (`nickname`, `profileImageURL`, `linkedSocialProvider`)

**범위 밖**:
- 저장한 스팟 목록 (`UserEndpoint.savedSpots`) — 별도 티켓
- 알림 설정, 이용약관/개인정보처리방침 페이지 본문 (외부 링크/별도 화면일 경우 라우팅만)
- 카카오/애플 로그인 자체 구현 (이미 `AuthService`에 존재, 비로그인 화면에서는 기존 Auth Feature 재사용)

> **계정관리 편집은 전부 포함** (닉네임 + 프로필이미지 변경/저장). 프로필 이미지 업로드 API는 백엔드 스펙 확정 후 구현 — `PATCH /v1/users/me`에 URL 필드 추가인지 별도 multipart endpoint인지 §13 (b) 논의.

---

## 2. 핵심 정책 결정 (사용자 확정)

| # | 항목 | 결정 |
|---|---|---|
| 1 | 비로그인 마이프로필 카피 | "마이페이지 이용을 위해\n로그인이 필요해요" (제목) + "지금 로그인하고 내가 공유한 스팟들과\n활동 내역을 한눈에 확인해 보세요." (부제). 카카오(노란 CTA) / Apple(흰 CTA) 두 버튼 |
| 2 | 비로그인 로그인 버튼 동작 | 기존 `Feature/Auth` 플로우로 진입. 성공 후 `AuthState` 변경 → 로그인 마이프로필 자동 전환 |
| 3 | 계정관리 진입 트리거 | 로그인 마이프로필 (`1014:24892`)에서 "계정 관리" 행 또는 헤더 액션. <!-- TODO: 정확한 진입 컴포넌트 위치는 `1014:24892` PNG 확보 후 확정 --> |
| 4 | 로그아웃 다이얼로그 카피 | 제목 "잠시 로그아웃하시겠어요?" / 본문 "로그아웃해도 저장하신 스팟 기록은 SNS 계정에 안전하게 보관됩니다." / 좌 "취소"(흰색) / 우 "로그아웃"(주황) |
| 5 | 로그아웃 후 동작 | `AuthService.signOut()` 호출 → `tokenStore.clear()` → 비로그인 마이프로필 자동 전환 (`AuthState` 관찰) |
| 6 | 회원탈퇴 사유 선택 UI | **single-select 드롭다운**. 닫힘 상태(`1067:5440`) → 펼침 상태(`1067:5499`) 1개 선택 → 다시 닫힘(`1063:5115`)에 선택된 사유 표시 |
| 7 | 회원탈퇴 사유 리스트 (확정) | (1) 원하는 스팟이 부족해요 (2) 앱 사용이 어려워요 (3) 자주 사용하지 않아요 (4) 오류나 불편함이 있어요 (5) 새 계정을 만들고 싶어요 (6) 개인정보가 걱정돼요 (7) 기타 |
| 8 | 회원탈퇴 동의 체크박스 | "안내사항을 모두 확인하였으며 이에 동의합니다." 체크 시에만 탈퇴 버튼 활성화 조건 충족 가능 |
| 9 | 탈퇴 버튼 활성화 조건 | **(사유 1개 선택) AND (동의 체크박스 ✓) AND (`selectedReason == .other` 이면 텍스트필드 non-empty)** 모두 충족 시 주황 활성. 하나라도 미충족 시 회색 비활성 |
| 10 | 기타 선택 시 사유 텍스트필드 | **표시함**. `selectedReason == .other` 일 때 텍스트필드 등장. 비어있으면 탈퇴 버튼 비활성 (§9 활성화 조건에 반영) |
| 11 | 회원탈퇴 API body | **전송함**. `UserEndpoint.deleteAccount`를 `(reason: WithdrawalReason, otherFeedback: String?)` 받도록 수정. body: `{ "reason": "...", "otherFeedback": "..." }` (백엔드와 키 네이밍 확인 후 확정) |
| 12 | 회원탈퇴 성공 후 동작 | 토큰 클리어 → 비로그인 마이프로필로 전환 (로그아웃과 동일 경로). 별도 "탈퇴 완료" 토스트/화면 여부 — <!-- TODO: 디자이너 컨펌 --> |

---

## 3. API 매핑

| UI 동작 | Endpoint | 비고 |
|---|---|---|
| 로그인 마이프로필 진입 시 프로필 로드 | `GET /v1/users/me` | **신규**: `UserEndpoint`에 `.me` 케이스 추가 필요 |
| 계정관리 진입 시 프로필 로드 | `GET /v1/users/me` | 동일 endpoint 재사용 또는 캐시 |
| 계정관리 닉네임 저장 | `PATCH /v1/users/me` (`UserEndpoint.updateProfile`) | 기존. `nickname` 파라미터로 호출. 범위 포함 시에만 |
| 계정관리 프로필 이미지 저장 | <!-- TODO: 이미지 URL 필드 추가 PATCH인지 별도 multipart endpoint인지 백엔드 스펙 확인 --> | 범위 포함 시에만 |
| 계정관리 → 로그아웃 버튼 → 팝업 확인 | `POST /v1/auth/logout` (`AuthEndpoint.logout`) | 기존, `AuthService.signOut()` 호출 |
| 회원탈퇴 → 탈퇴하기 버튼 | `DELETE /v1/users/me` (`UserEndpoint.deleteAccount`) | **수정**: `(reason:String, otherFeedback:String?)` 파라미터로 변경, body 인코딩 추가. `UserService.deleteAccount(reason:otherFeedback:)` 메서드 신설 |
| 비로그인 → 카카오 로그인 | `POST /v1/auth/kakao` (`AuthEndpoint.kakaoSignIn`) | 기존 Auth Feature 재사용 |
| 비로그인 → 애플 로그인 | `POST /v1/auth/apple` (`AuthEndpoint.appleSignIn`) | 기존 Auth Feature 재사용 |

JSONDecoder는 `convertFromSnakeCase` 전역 적용 → 모델엔 CodingKeys 박지 않는다.

---

## 4. 신규/수정 파일 목록

**신규**
```
Pickflow/Sources/Feature/MyProfile/
  MyProfileView.swift                       // 비로그인/로그인 분기 컨테이너
  MyProfileViewModel.swift
  Components/
    MyProfileSignedOutContent.swift         // 1032:4848 본체
    MyProfileSignedInContent.swift          // 1014:24892 본체
    MyProfileMenuRow.swift                  // 메뉴 행 공용
  AccountManagement/
    AccountManagementView.swift             // 1014:25012
    AccountManagementViewModel.swift
    Components/
      LogoutConfirmDialog.swift             // 1067:5258
  Withdrawal/
    WithdrawalReasonView.swift              // 1067:5440 (+5553 텍스트필드 상태)
    WithdrawalConfirmView.swift             // 1067:5499 / 1063:5115
    WithdrawalViewModel.swift
    Models/
      WithdrawalReason.swift                // enum, Codable
PickflowTests/MyProfile/
  MyProfileViewModelTests.swift
  AccountManagementViewModelTests.swift
  WithdrawalViewModelTests.swift
  __Snapshots__/                            // Phase C에서 생성
```

**수정**
- `Pickflow/Sources/Core/Services/Endpoints/UserEndpoint.swift` — `.me` 케이스 추가 (`GET /v1/users/me`). 필요 시 `.deleteAccount` body 파라미터화
- `Pickflow/Sources/Core/Services/UserService.swift` — `fetchCurrentUser()` 실제 구현, `deleteAccount(...)` 메서드 추가
- `Pickflow/Sources/Core/Services/Protocols/UserServiceProtocol.swift` — `User` 모델 필드 확장(Figma 확인 후), `deleteAccount` 시그니처 추가
- `Pickflow/Sources/Feature/Profile/ProfileView.swift`, `ProfileViewModel.swift` — 삭제 (MyProfile로 대체) 또는 진입점만 위임
- `Pickflow/Sources/App/AppContainer.swift` (또는 DI 등록 파일) — 신규 ViewModel/Service 의존성 확인
- `Pickflow/Sources/App/*` — 탭 라우팅에서 ProfileView → MyProfileView로 교체 (탭 진입점 위치는 작업 시 확인)

---

## 5. 모델 정의 가이드

```swift
// 기존 User 확장 (Protocols/UserServiceProtocol.swift)
struct User: Codable, Sendable {
    let id: String
    let nickname: String           // 기존 `name` → `nickname` 변경. 백엔드 응답 키 확인
    let email: String
    let profileImageURL: URL?      // 계정관리에서 표시. nil 시 기본 placeholder
    let linkedSocialProvider: SocialProvider   // "카카오로 로그인됨"/"Apple로 로그인됨" 표시용
}

enum SocialProvider: String, Codable, Sendable {
    case kakao
    case apple
}

// Feature/MyProfile/Withdrawal/Models/WithdrawalReason.swift
// Figma `1067:5499` 드롭다운 항목 순서·문구 그대로 (single-select)
enum WithdrawalReason: String, CaseIterable, Codable, Sendable, Identifiable {
    case insufficientSpots       // 원하는 스팟이 부족해요
    case difficultToUse          // 앱 사용이 어려워요
    case rarelyUsed              // 자주 사용하지 않아요
    case bugsOrIssues            // 오류나 불편함이 있어요
    case newAccount              // 새 계정을 만들고 싶어요
    case privacyConcerns         // 개인정보가 걱정돼요
    case other                   // 기타

    var id: String { rawValue }
    var displayText: String {
        switch self {
        case .insufficientSpots: "원하는 스팟이 부족해요"
        case .difficultToUse:    "앱 사용이 어려워요"
        case .rarelyUsed:        "자주 사용하지 않아요"
        case .bugsOrIssues:      "오류나 불편함이 있어요"
        case .newAccount:        "새 계정을 만들고 싶어요"
        case .privacyConcerns:   "개인정보가 걱정돼요"
        case .other:             "기타"
        }
    }
}

struct WithdrawalRequest: Encodable, Sendable {
    let reason: WithdrawalReason       // single-select, rawValue 그대로 전송
    let otherFeedback: String?         // .other 선택 시에만 non-nil. 그 외엔 nil
}
// 백엔드 키 네이밍 (`reason`/`other_feedback` 등) §13 (c) 마감 시 확정 — convertToSnakeCase 적용 시 자동.
```

---

## 6. ViewModel 시그니처

```swift
@MainActor
final class MyProfileViewModel: ObservableObject {
    enum LoadState: Equatable {
        case signedOut
        case loading
        case signedIn(User)
        case failed(String)
    }
    @Published private(set) var state: LoadState = .loading

    init(userService: UserServiceProtocol, authService: AuthServiceProtocol)

    func onAppear() async             // currentAuthState 확인 → signedIn이면 fetchCurrentUser
    func refresh() async
}

@MainActor
final class AccountManagementViewModel: ObservableObject {
    @Published var nicknameDraft: String = ""
    @Published private(set) var user: User?
    @Published private(set) var saveState: SaveState = .idle      // 닉네임/프로필이미지 저장 (스코프 포함 시)
    @Published private(set) var logoutState: LogoutState = .idle

    enum SaveState: Equatable { case idle, saving, saved, failed(String) }
    enum LogoutState: Equatable { case idle, confirming, processing, done, failed(String) }

    var isSaveEnabled: Bool { /* 닉네임 dirty + 유효성 OK */ }

    init(userService: UserServiceProtocol, authService: AuthServiceProtocol)

    func onAppear() async             // fetchCurrentUser → user 세팅, nicknameDraft 초기화
    func save() async                 // PATCH /v1/users/me

    func requestLogout()              // .idle → .confirming (다이얼로그 표시)
    func confirmLogout() async        // .confirming → .processing → .done | .failed
    func cancelLogout()               // .confirming → .idle
}

@MainActor
final class WithdrawalViewModel: ObservableObject {
    enum Step: Equatable { case input, processing, done, failed(String) }
    @Published private(set) var step: Step = .input
    @Published var selectedReason: WithdrawalReason?      // single-select
    @Published var isDropdownOpen: Bool = false
    @Published var otherFeedback: String = ""             // §2 #10 확정 시 사용
    @Published var didAgreeToTerms: Bool = false

    // Figma `1063:5115` 활성화 조건 (§2 #9 확정)
    var canSubmit: Bool {
        guard let reason = selectedReason, didAgreeToTerms else { return false }
        if reason == .other && otherFeedback.trimmingCharacters(in: .whitespaces).isEmpty {
            return false
        }
        return true
    }

    init(userService: UserServiceProtocol, authService: AuthServiceProtocol)

    func selectReason(_ reason: WithdrawalReason)
    func toggleDropdown()
    func toggleAgreement()
    func submitWithdrawal() async     // .input → .processing → .done | .failed
}
```

DI: `AppContainer.registerDependencies()`에 신규 ViewModel은 보통 등록하지 않고, 진입점에서 `getUserService()`/`getAuthService()` 헬퍼로 주입. 패턴은 KAN-51 SpotDetail 참조.

---

## 7. 외부 앱 / 시스템 연동

없음 — My Profile 화면은 외부 URL scheme이나 시스템 sheet에 의존하지 않는다.
(이용약관/개인정보처리방침 외부 링크가 있을 경우 §1 범위 밖)

---

## 8. 화면별 정밀 사양

- **비로그인 마이프로필** (`1032:4848`): 상단 좌측 `PICKFLOW` 워드마크, 중앙 카피 2줄 + 부제 2줄, 카카오(노란 #FAE100 계열) / Apple(흰색) 로그인 CTA 풀폭. 하단 탭바 "마이" 활성 상태
- **로그아웃 다이얼로그** (`1067:5258`): **커스텀 모달** (SwiftUI `.confirmationDialog` 아님 — 디자인이 시트가 아닌 alert-like 카드). 백드롭은 계정관리 화면 어둡게 dim. 좌(취소-흰색) / 우(로그아웃-주황) 버튼 동일 크기. iOS alert 톤 아님
- **회원탈퇴 사유 드롭다운**: **single-select**. 닫힘 상태(`1067:5440`)에선 placeholder "탈퇴 사유를 선택해주세요" + `▼` chevron, 펼침 상태(`1067:5499`)는 항목 리스트가 카드 내부에 inline 펼침 (별도 시트 아님). 선택된 항목은 주황색 텍스트 + 우측 ✓
- **기타 텍스트필드** (`1067:5553`): **표시 여부 사용자 컨펌 필요** (§2 #10). 표시한다면 max length·placeholder는 디자이너 확인 필요
- **탈퇴 동의 체크박스**: 비체크는 빈 사각, 체크는 주황 채움 + ✓. 라벨 "안내사항을 모두 확인하였으며 이에 동의합니다."
- **탈퇴 버튼 활성/비활성** (`1063:5115`): 비활성 회색 (`#3A3A3C` 계열), 활성 주황 (`#FF6B35` 계열). 비활성에서도 텍스트는 표시. §9.1에서 정확한 hex 확정

---

## 9. 디자인 시스템 추가 — **에셋 입력 매트릭스 (Gate 4)**

> **이 두 매트릭스가 모두 채워진 다음에야 §10 Phase A를 시작한다.** 미채움 상태로 Phase A 진입 금지.
>
> **아래는 PNG 추정값.** Phase A 진입 직전 Figma dev mode 또는 REST API로 정확한 hex/사이즈를 확정한다. 추정값으로 코딩 진입 금지.

### 9.1 컬러 매트릭스 (PNG 추정 — 확정 전)

| 토큰명 (제안) | Figma node | hex 추정 | 용도 |
|---|---|---|---|
| `bgPrimary` | 1014:24892 / 1014:25012 / 1032:4848 | `#000000` ~ `#0A0A0A` | 화면 전체 배경 (다크) |
| `surfaceField` | 1014:25012 | `#2C2C2E` 계열 | 닉네임/연결된 소셜 입력 필드 배경 |
| `surfaceCardModal` | 1067:5258 | `#1C1C1E` ~ `#2C2C2E` | 로그아웃 다이얼로그 카드 배경 |
| `surfaceWarningBox` | 1067:5440 | `#1C1C1E` 계열 | 탈퇴 유의사항 안내 박스 |
| `textPrimary` | 전체 | `#FFFFFF` | 본문 흰색 |
| `textSecondary` | 1014:25012, 1067:5440 | `#8E8E93` ~ `#AEAEB2` | 부제·라벨·placeholder |
| `accentOrange` | 1067:5258 / 1063:5115 / 1067:5440 강조 | `#FF6B35` (확인 필요) | CTA·체크박스·강조 텍스트 |
| `accentKakao` | 1032:4848 | `#FAE100` (확인 필요) | 카카오 로그인 버튼 |
| `dangerRed` | 1014:25012 "회원탈퇴" | `#FF453A` 계열 | 회원탈퇴 텍스트 라벨 |
| `buttonDisabled` | 1067:5440 비활성 탈퇴 버튼 | `#3A3A3C` 계열 | 비활성 CTA |

추가 후 `tuist generate` 시 `UIAsset.Colors.*`에 자동 추가됨. **`tuist generate` 전에 Figma dev mode에서 실제 hex 재확인 필수.**

### 9.2 아이콘/이미지 매트릭스

| 에셋명 (제안) | Figma node | export 포맷 | 사이즈 | 용도 |
|---|---|---|---|---|
| `icon-back-chevron` | 1014:25012 / 1067:5440 | SVG | 24×24 | 상단 좌측 back 버튼 |
| `icon-camera-overlay` | 1014:25012 | SVG | 32×32 | 프로필 이미지 우하단 카메라 오버레이 |
| `icon-profile-placeholder` | 1014:25012 | SVG | 80×80 | 프로필 이미지 비어있을 때 placeholder |
| `icon-chevron-down` | 1067:5440 | SVG | 20×20 | 사유 드롭다운 닫힘 chevron |
| `icon-chevron-up` | 1067:5499 | SVG | 20×20 | 사유 드롭다운 펼침 chevron |
| `icon-check-orange` | 1067:5499 | SVG | 20×20 | 선택된 사유 ✓ |
| `icon-checkbox-empty` | 1067:5440 | SVG | 20×20 | 동의 체크박스 비체크 |
| `icon-checkbox-checked` | 1063:5115 | SVG | 20×20 | 동의 체크박스 체크 |
| `icon-kakao` | 1032:4848 | SVG | 24×24 | 카카오 로그인 버튼 아이콘 |
| `icon-apple` | 1032:4848 | SVG | 24×24 | Apple 로그인 버튼 아이콘 |
| `icon-tab-explore` / `icon-tab-bookmark` / `icon-tab-my` | 1032:4848 | SVG | 24×24 | 탭바 (이미 존재 시 재사용) |

`Pickflow/Resources/Assets.xcassets/<name>.imageset/`에 등록. 사이즈는 PNG 추정 — Figma export 시 확정.

### 9.3 타이포 매핑 (사용한 토큰만)

| 사용처 | 토큰 (확인 필요) | 폴백 |
|---|---|---|
| 비로그인 화면 제목 ("마이페이지 이용을 위해 ...") | `.pretendard(.semiBold, 20)` 계열 | system |
| 비로그인 부제 | `.pretendard(.regular, 14)` 계열 | system |
| 화면 타이틀 ("계정 관리", "회원탈퇴") | `.pretendard(.semiBold, 18)` | system |
| 섹션 라벨 ("닉네임", "연결된 소셜", "탈퇴 유의사항 안내") | `.pretendard(.medium, 14)` | system |
| 입력 필드 텍스트 | `.pretendard(.regular, 16)` | system |
| 다이얼로그 타이틀 ("잠시 로그아웃하시겠어요?") | `.pretendard(.semiBold, 17)` | system |
| 다이얼로그 본문 | `.pretendard(.regular, 14)` | system |
| 다이얼로그 / 탈퇴 CTA 라벨 | `.pretendard(.semiBold, 16)` | system |
| 사유 항목 텍스트 | `.pretendard(.regular, 16)` | system |
| 회원탈퇴 텍스트 (계정관리 행) | `.pretendard(.medium, 14)` | system |

> 위 토큰은 `PickflowTypography.swift`의 기존 토큰과 1:1 매칭되는지 Phase A 진입 전 확인. 매칭 안 되면 토큰 추가.

> 매트릭스 채움 자가 점검:
> - [ ] §9.1, §9.2가 비어 있지 않다
> - [ ] 각 행이 실제 Figma 노드를 가리키고 hex/사이즈가 명시되어 있다
> - [ ] 누락된 토큰이 `<!-- TODO -->`가 아니라 실제 값으로 채워졌다

위 3개 모두 통과해야 Phase A 진입.

---

## 10. TDD A→B→C 오케스트레이션 (Gate 1)

> **A → B → C는 직렬이다. 단계 건너뛰기·병렬화·역순 모두 금지.**
> 각 단계의 진입/작업/종료 디테일은 리프 문서에서 봄. 이 섹션은 **순서와 게이트만** 명시한다.

```
§9 에셋 매트릭스 (Gate 4)
        ↓
Phase A — ViewModel TDD (Gate 1A)
  · 진입: §3, §6, §9 모두 확정
  · 작업: 인터랙션별 RED → GREEN, SwiftUI 뷰 0줄
  · 대상: MyProfileViewModel, AccountManagementViewModel, WithdrawalViewModel
  · 종료: 세 ViewModel 테스트 100% green, 뷰 파일 0개
  · 가이드: docs/phases/phase-a-viewmodel-tdd.md ← Phase A 들어갈 때 읽기
        ↓
Phase B — ui-test-cases.md (Gate 1B + Gate 2)
  · 진입: Phase A 종료 조건 통과
  · 작업: docs/KAN-54/ui-test-cases.md 8컬럼 표 작성
  · 종료: TODO 0개, 행마다 스냅샷 파일명 결정
  · 가이드: docs/phases/phase-b-ui-cases.md ← Phase B 들어갈 때 읽기
        ↓
Phase C — Snapshot + UI (Gate 1C + Gate 3)
  · 진입: Phase B 종료 조건 통과
  · 작업: swift-snapshot-testing 케이스 RED → SwiftUI 뷰 → GREEN
  · 종료: 매트릭스 전 케이스 green, Figma 비교 루프 1회
  · 가이드: docs/phases/phase-c-snapshot.md ← Phase C 들어갈 때 읽기
```

> 각 Phase에 **들어갈 때** 해당 리프 문서를 read한다. 미리 다 읽어두지 않는다 — 단계 격리가 게이트의 본체다.

---

## 11. UI 검증 루프 (Figma 노드별 비교, Phase C 마무리)

| 컴포넌트 | Figma node-id | 확인 항목 |
|---|---|---|
| 비로그인 마이프로필 | `1032:4848` | PICKFLOW 워드마크, 카피 2줄+부제 2줄, 카카오/Apple CTA 컬러·라운드, 탭바 활성 |
| 로그인 마이프로필 | `1014:24892` | 닉네임/이메일 표시, 메뉴 리스트, 프로필 이미지 영역 — **PNG 미확보, Figma 재방문 필요** |
| 계정관리 (편집 모드 초기) | `1014:25012` | 프로필이미지+카메라 오버레이, 닉네임 입력 필드, 연결된 소셜 라벨/placeholder, 로그아웃/회원탈퇴 텍스트 배치, "저장" 비활성 |
| 로그아웃 확인 다이얼로그 | `1067:5258` | 카드 배경, 타이틀/본문 카피, 좌(취소-흰)/우(로그아웃-주황) 버튼, 백드롭 dim |
| 회원탈퇴 - 사유 미선택 | `1067:5440` | 유의사항 안내 박스(주황 강조 텍스트), 드롭다운 닫힘+placeholder, 동의 체크박스 비체크, 탈퇴 버튼 비활성 |
| 회원탈퇴 - 사유 드롭다운 펼침 | `1067:5499` | 7개 사유 순서/문구, 선택된 항목 주황+✓, 펼침 chevron 방향 |
| 회원탈퇴 - 기타 선택 시 텍스트필드 | `1067:5553` | **§2 #10 확정 후 검증**. 텍스트필드 표시 조건/placeholder/높이 |
| 회원탈퇴 - 모든 조건 충족 | `1063:5115` | 드롭다운 닫힘+선택값 표시, 체크박스 체크 ✓, 탈퇴 버튼 주황 활성 |

각 노드 조회: Figma REST `GET /files/LyduUVMjsQi0qyUsENriR5/nodes?ids=...` (토큰은 `reference_figma.md`). MCP rate limit 시 REST 폴백.

---

## 12. 디버그 진입점

```swift
@State private var isMyProfilePresented = false

Button("My Profile 열기") { isMyProfilePresented = true }
    .fullScreenCover(isPresented: $isMyProfilePresented) {
        MyProfileView(viewModel: MyProfileViewModel(
            userService: getUserService(),
            authService: getAuthService()
        ))
    }
```

탭바에 이미 진입점이 있을 경우 별도 디버그 버튼 불필요 — 현재 `Profile` 탭 라우팅을 `MyProfileView`로 교체.

---

## 13. 논의 포인트 MD

`docs/KAN-54/my-profile-discussion.md` — 후속 합의 필요 항목.
- (a) 프로필 이미지 업로드 API 스펙 — `PATCH /v1/users/me` body에 URL 필드 추가 vs 별도 multipart endpoint (§3)
- (b) 회원탈퇴 API body 키 네이밍 — `reason`/`other_feedback` 등 백엔드 정확한 키 (§5)
- (c) 회원탈퇴 성공 후 별도 토스트/완료 화면 여부 (§2 #12)
- (d) 로그인 마이프로필 (`1014:24892`) 컴포넌트 구성 — Figma rate limit 해제 후 REST 재시도 또는 PNG 추가 확보 필요. Phase A 진입 전 해결 필수

---

## 14. 마감 체크리스트

각 Phase 리프 문서에 단계별 종료 조건이 있다. 여기서는 **PR 머지 직전 한 번 더 확인할 게이트만** 모은다.

**게이트 통과**
- [ ] Gate 1 (TDD A→B→C 직렬): 단계 순서 위반 없음
- [ ] Gate 2 (`ui-test-cases.md`): TODO 0개, 8컬럼 채움
- [ ] Gate 3 (swift-snapshot-testing): 매트릭스 전 케이스 green, `__Snapshots__/` PR 첨부, record 블라인드 덮어쓰기 0건
- [ ] Gate 4 (에셋 매트릭스): §9.1·§9.2 채움 후에 Phase A 시작했음

**일반**
- [ ] `SWIFT_STRICT_CONCURRENCY: complete` 빌드 경고/에러 0
- [ ] §11 Figma 비교 루프 1회 이상 (8개 노드 전부)
- [ ] §12 디버그 진입점에서 시뮬레이터 동작 확인
- [ ] 로그아웃/탈퇴 후 `AuthState` 전환 → 비로그인 화면 정상 진입 검증
- [ ] `docs/KAN-54/my-profile-discussion.md` 작성

> 단계 내부 체크리스트(예: "Phase A 종료 조건")는 해당 리프 문서를 본다. 여기 중복으로 박지 않는다.

---

## 15. 작업 순서 요약

```
0. §0~§8 합의 → §13 논의 포인트 (b)(c) 사용자 확정 → §9 에셋 매트릭스 채움 (Gate 4)
        ↓
1. docs/phases/phase-a-viewmodel-tdd.md 읽기 → Phase A 수행 (Gate 1A)
   - UserEndpoint.me 추가 + UserService 구현부터
   - MyProfileViewModel → AccountManagementViewModel → WithdrawalViewModel 순
        ↓
2. docs/phases/phase-b-ui-cases.md 읽기 → Phase B 수행 (Gate 1B + 2)
        ↓
3. docs/phases/phase-c-snapshot.md 읽기 → Phase C 수행 (Gate 1C + 3) → §11 Figma 루프
        ↓
4. §12 디버그 검증 → §13 논의 포인트 → §14 통과 → PR
```

> 순서를 어겼다면 PR 본문에 어디서 거꾸로 갔는지 명시. 단계 건너뛰기는 회귀 비용으로 직결된다.
