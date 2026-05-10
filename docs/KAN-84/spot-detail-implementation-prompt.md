# [KAN-84] 스팟 상세 정보 화면 리뉴얼 구현 통합 프롬프트

> **이 프롬프트의 사용법**: 이 파일을 읽고 나서 해당 Phase 리프 문서를 그때그때 읽는다.
>
> **방법론은 여기 없다.** TDD 단계별 디테일은 단계 진입 시 리프 문서를 읽는다:
> - Phase A: `docs/phases/phase-a-viewmodel-tdd.md`
> - Phase B: `docs/phases/phase-b-ui-cases.md`
> - Phase C: `docs/phases/phase-c-snapshot.md`
>
> 본 문서는 **이 화면에만 해당하는 사실**(스코프, API, 정책, 에셋, 컴포넌트 매핑)을 담는다.

---

## 0. 작업 컨텍스트 (선결 정보)

**브랜치**: `feature/KAN-84` (develop에서 분기/체크아웃됨)  
**티켓**: `https://dddios1.atlassian.net/browse/KAN-84`  
**Figma 파일 키**: `LyduUVMjsQi0qyUsENriR5`

| 케이스 | Figma node-id | 이름 |
|---|---|---|
| Default 북마크 OFF | `926:17618` | Detail-Default-General-01 |
| Default 북마크 ON | `926:17693` | Detail-Default-General-02 |
| My스팟 | `926:17963` | Detail-Default-My |

**Figma 접근**: MCP 스타터 한도 초과 → **Figma REST API** 사용  
- Token: memory `reference_figma.md` 참고  
- `GET https://api.figma.com/v1/images/LyduUVMjsQi0qyUsENriR5?ids=<nodeId>&format=png&scale=2`  
- `GET https://api.figma.com/v1/files/LyduUVMjsQi0qyUsENriR5/nodes?ids=<nodeId>`

**프로젝트 가정 (재탐색 불필요)**:
- SwiftUI + MVVM, Tuist 매니페스트(`Project.swift`)
- 외부 의존성: Alamofire, Swinject, KakaoSDK*, nMapsMap, FirebaseMessaging
- DI: `AppContainer.shared.registerDependencies()` → `getXxxService()` MainActor 헬퍼
- 디자인 시스템: `Resources/DesignSystem/Colors.xcassets` → `UIAsset.Colors.*` 자동 생성, `.pretendard(...)` 토큰
- 테스트 타겟 `PickflowTests` 존재. 신규 테스트는 거기에 추가
- `SWIFT_STRICT_CONCURRENCY: complete` — 모든 신규 타입 `Sendable`/`@MainActor` 명시
- 선례: `Feature/SpotDetail/*` (KAN-51) — **이번은 리뉴얼이므로 기존 파일을 수정/삭제함**
- JSON 디코더: `convertFromSnakeCase` 전역 적용 → CodingKeys 박지 않는다

---

## 1. 스코프

**구현 범위**:
- `SpotDetailNavBar` 수정 — 좌: 뒤로가기 아이콘 추가 / 우: 공유 아이콘 + X (북마크 제거)
- `SpotHeaderSection` 수정 — 거리 뱃지→북마크수, MY스팟 뱃지, 코멘트 텍스트 흡수
- `SpotPhotoSection` 수정 — 날짜/시간 뱃지 오버레이 + 위치 아이콘 + 주소 행 추가
- `SpotActionButtons` 수정 — Default: 길안내(넓게)+북마크아이콘(정사각) / My스팟: 길안내+내스팟오픈
- `SpotRealTimeInfoSection` 신규 — 기존 3개 섹션(날씨/기온혼잡도/일몰타임라인) 대체
- `SpotDetail` / `SpotWeather` 모델 확장 — `bookmarkCount`, `isMine`, `parking` (§2 확정 후)
- `reportInvalidInfo()` 실제 API 연동 — `POST /v1/spots/{spotId}/reports`
- 기존 컴포넌트 제거: `SpotCommentSection`, `SpotWeatherSection`, `SpotTempCongestionSection`, `SunsetTimelineSection`
- 테스트 더블 업데이트: `SpotDetailDebugMocks.swift`, `SpotDetailTestDoubles.swift`

**범위 밖**:
- "내 스팟 오픈하기" API 연동 — 백엔드 스펙 미확정. 버튼 UI만 추가, 탭 시 stub
- 스팟 등록/편집 화면 변경
- 지도 화면 변경
- 일몰 타임라인 UI 재사용 (삭제 대상)

---

## 2. 핵심 정책 결정 (구현 전 백엔드 확인 필수)

| # | 항목 | 결정 |
|---|---|---|
| 1 | `bookmarkCount` | GET `/spots/{id}` 응답에 포함되는지 확인 필요. 포함이면 `SpotDetail`에 추가, 아니면 별도 API 또는 숨김 처리 |
| 2 | `isMine` | 서버가 인증 토큰 기반으로 응답에 포함하는지 확인. 클라이언트 판단 불가(로그인 사용자만 My스팟) |
| 3 | `parking` | `SpotWeather`에 포함되는지 확인. 공공 API 제공 여부에 따라 nullable |
| 4 | "내 스팟 오픈하기" API | 스팟 공개 전환 API 스펙 전무 → Phase C에서 stub 처리, 후속 티켓으로 분리 |
| 5 | 일몰 "오차 시간" | Figma에서 "오차 시간" 텍스트가 서브레이블인지, `±N분` 값인지 확인 필요 |
| 6 | My스팟 주차/혼잡도 `-` | 서버가 null로 내려주는 건지, `isMine` 플래그로 클라이언트가 처리하는 건지 확인 |
| 7 | NavBar 뒤로가기 vs X | 두 버튼 모두 `dismiss()`인지, 뒤로가기는 push pop인지 — 화면 진입 방식(push/modal) 확인 |

---

## 3. API 매핑

| UI 동작 | Endpoint | 현재 구현 | 비고 |
|---|---|---|---|
| 화면 진입 시 데이터 로드 | `GET /v1/spots/{spotId}?latitude=&longitude=` | ✅ `SpotEndpoint` + `SpotService.fetchSpotDetail` | `bookmarkCount`, `isMine`, `parking` 신규 필드 확인 필요 |
| 북마크 추가 | `POST /v1/spots/{spotId}/bookmarks` | ✅ `BookmarkEndpoint` | 액션 버튼으로 이동 |
| 북마크 해제 | `DELETE /v1/spots/{spotId}/bookmarks` | ✅ `BookmarkEndpoint` | 동일 |
| 잘못된 정보 신고 | `POST /v1/spots/{spotId}/reports` | ⚠️ stub (`reportInvalidInfo` 미구현) | 이번 티켓에서 연동 |
| 공유하기 | 시스템 UIActivityViewController | ✅ `ShareSheetPresenter` | NavBar 공유 아이콘으로 이동 |
| 길 안내 받기 | nmap:// 외부 앱 | ✅ `ExternalAppLauncher` | 유지 |
| 내 스팟 오픈하기 | 미정 | ❌ 없음 | stub 처리 |

---

## 4. 신규/수정/제거 파일 목록

**신규**
```
Pickflow/Sources/Feature/SpotDetail/Components/
  SpotRealTimeInfoSection.swift   ← 아이콘+라벨 카드 4행 (날씨/일몰/주차/혼잡도)
```

**수정**
```
Pickflow/Sources/Core/Services/Models/Spot.swift
  └─ SpotDetail: bookmarkCount, isMine 추가 (BE 확인 후)
  └─ SpotWeather: parking 추가 (BE 확인 후)

Pickflow/Sources/Feature/SpotDetail/
  ├─ SpotDetailView.swift          ← 섹션 조립 변경
  ├─ SpotDetailViewModel.swift     ← share() NavBar 연결, openSpot() stub 추가
  └─ SpotDetailDebugMocks.swift    ← 신규 필드 반영

Pickflow/Sources/Feature/SpotDetail/Components/
  ├─ SpotDetailNavBar.swift        ← 뒤로가기 추가, 공유↔북마크 교체
  ├─ SpotHeaderSection.swift       ← 거리→북마크수, MY뱃지, 코멘트 흡수
  ├─ SpotPhotoSection.swift        ← 날짜뱃지 오버레이, 주소 행 추가
  └─ SpotActionButtons.swift       ← Default/My스팟 분기 레이아웃

PickflowTests/
  ├─ SpotDetailViewModelTests.swift
  └─ Helpers/SpotDetailTestDoubles.swift
```

**제거**
```
Pickflow/Sources/Feature/SpotDetail/Components/
  ├─ SpotCommentSection.swift      ← SpotHeaderSection으로 흡수
  ├─ SpotWeatherSection.swift      ← SpotRealTimeInfoSection으로 대체
  ├─ SpotTempCongestionSection.swift
  └─ SunsetTimelineSection.swift
```

---

## 5. 모델 정의 가이드

```swift
// Spot.swift — 신규 필드 (BE 확인 후 추가)
struct SpotDetail: Codable, Sendable, Identifiable, Equatable {
    let id: Int64
    let name: String
    let comment: String
    let theme: SpotTheme
    let latitude: Double
    let longitude: Double
    let distance: Double?           // 유지 (UI 미사용 → 추후 제거 여지)
    let address: String             // 이미 있음 — 주소 행에 사용
    let images: [SpotImage]
    let isBookmarked: Bool
    let bookmarkCount: Int          // 신규 — BE 확인 필요 (없으면 옵셔널 처리)
    let isMine: Bool                // 신규 — BE 확인 필요
    let weather: SpotWeather

    var primaryImage: SpotImage? {
        images.sorted { $0.displayOrder < $1.displayOrder }.first
    }
}

struct SpotWeather: Codable, Sendable, Equatable {
    let temperature: Int
    let precipitationProbability: Int
    let condition: WeatherCondition
    let sunsetTime: String
    let congestion: Congestion
    let parking: String?            // 신규 — BE 확인 필요
}

// SpotReportType (신규 — reportInvalidInfo 연동용)
enum SpotReportType: String, Codable, Sendable {
    case locationError = "LOCATION_ERROR"
    case wrongName = "WRONG_NAME"
    case etc = "ETC"
}

struct SpotReportRequest: Encodable, Sendable {
    let reportType: SpotReportType
}
```

---

## 6. ViewModel 시그니처

기존 `SpotDetailViewModel`을 수정한다. 시그니처 변경 최소화.

```swift
@MainActor
final class SpotDetailViewModel: ObservableObject {
    // 기존 유지
    enum LoadState: Equatable {
        case idle, loading, loaded(SpotDetail), failed(String)
    }
    @Published private(set) var state: LoadState = .idle
    @Published private(set) var isBookmarked = false
    @Published var dismissRequested = false
    @Published var toast: String?

    // 기존 유지 — 시그니처 변경 없음
    func onAppear() async
    func toggleBookmark() async     // 액션 버튼으로 호출 위치 변경 (내부 로직 유지)
    func openNaverMapsRoute()
    func share()                    // NavBar 공유 아이콘으로 호출 위치 변경 (내부 로직 유지)
    func reportInvalidInfo()        // stub → 실제 API 연동
    func close()

    // 신규
    func openSpot()                 // My스팟 "내 스팟 오픈하기" — 이번은 stub
}
```

`reportInvalidInfo()` 연동 시 `SpotServiceProtocol`에 `reportSpot(id:type:)` 추가 필요.

---

## 7. 외부 앱 / 시스템 연동

이미 구현됨 (`ExternalAppLauncher`, `ShareSheetPresenter`) — 유지.

| 연동 | 현재 상태 |
|---|---|
| 네이버지도 `nmap://` | ✅ `ExternalAppLauncher.openNaverMapsRoute` |
| 시스템 공유 sheet | ✅ `ShareSheetPresenter.present` |

변경 사항: `share()` 호출 위치가 `SpotActionButtons` → `SpotDetailNavBar`로 이동.

---

## 8. 화면별 정밀 사양

### 8.1 SpotActionButtons — 레이아웃 분기

```
Default (isMine == false):
  HStack(spacing: 12) {
    [길 안내 받기]  width: 넓게(FILL), height: 56, background: sunsetOrange
    [북마크 아이콘] width: 56, height: 56, background: gray0, cornerRadius: 8
  }

My스팟 (isMine == true):
  HStack(spacing: 12) {
    [길 안내 받기]     width: FILL, height: 52
    [내 스팟 오픈하기] width: FILL, height: 52
  }
  // 두 버튼 동일 너비 (각 173pt @ 390pt 화면)
```

### 8.2 SpotRealTimeInfoSection — 행 구조

```
[아이콘 36x36] [VERTICAL]
                 [TEXT] 레이블 (현재 날씨 / 일몰 시간 / 주차 관련 / 혼잡도)  17pt Regular gray50
                 [HStack]
                   [TEXT] 값 (맑음 / PM 6:40 / 무료 주차장 / 여유)           24pt SemiBold gray0
                   [TEXT] 보조값 (강수 확률 15% / 오차 시간 / — / —)          15pt Regular gray50
행 height: 54pt, 아이콘 컨테이너: 54x54pt
```

My스팟 케이스에서 주차/혼잡도 값은 `-` (정책 §2-6 확인 후 처리 방식 결정).

### 8.3 SpotPhotoSection — 날짜 뱃지

`primaryImage.recordedTime` → `DateFormatter.pickflowDisplayTime` 변환  
뱃지 형식: `"26.04.11. PM 6:33"`, 이미지 우하단 오버레이, 패딩 8pt.

---

## 9. 디자인 시스템 추가 — **에셋 입력 매트릭스 (Gate 4)**

> **이 두 매트릭스가 모두 채워진 다음에야 §10 Phase A를 시작한다.** 미채움 상태로 Phase A 진입 금지.

### 9.1 컬러 매트릭스

| 토큰명 | Figma node | hex (Light) | 용도 |
|---|---|---|---|
| `gray0` | — | 기존 | 텍스트, 버튼 bg |
| `gray10` | — | 기존 | 뱃지 텍스트 |
| `gray30` | — | 기존 | 보조 텍스트 |
| `gray50` | — | 기존 | 레이블, 비활성 |
| `gray80` | — | 기존 | 토스트 bg |
| `gray90` | — | 기존 | 뱃지 bg |
| `gray95` | — | 기존 | 화면 bg |
| `sunsetOrange` | — | 기존 | 길안내 버튼 |

신규 컬러: Figma REST API로 node 확인 후 채울 것. 현재 분석상 기존 토큰으로 커버 예상.

> - [ ] §9.1 신규 컬러 없음을 Figma에서 최종 확인함
> - [ ] 확인 전 Phase A 진입 금지

### 9.2 아이콘/이미지 매트릭스

| 에셋명 (프로젝트 camelCase) | Figma 컴포넌트명 | 사이즈 | 용도 | 현재 상태 |
|---|---|---|---|---|
| `icArrowBackIos` | `ic_arrow_back_ios` | 28x28 | NavBar 뒤로가기 | ✅ 등록 완료 (PDF) |
| `icShare` | `ic_share` | 32x32 | NavBar 공유 | ✅ 등록 완료 (PDF) |
| `icClose` | `ic_close` | 32x32 | NavBar X | ✅ 등록 완료 (PDF) |
| `icLocationOn` | `ic_location_on` | 16x16 | 주소 행 위치 아이콘 | ✅ 등록 완료 (PDF) |
| `icNearMe` | `ic_near_me` | 24x24 | 길안내 버튼 아이콘 | ✅ 등록 완료 (PDF) |
| `icBookmarkBorder` | `ic_bookmark_border` | 24x24 | 액션 버튼 북마크 OFF | ✅ 기존 (`icBookmarkBorder`) |
| `icBookmarkFilled` | `ic_bookmark` | 24x24 | 액션 버튼 북마크 ON | ✅ 기존 (`icBookmarkFilled`) |
| `icSunny` | `ic_sunny` | 36x36 | 실시간 정보 현재날씨 | ✅ 기존 (`icSunny`) |
| `icTwilight` | `ic_twighlight` | 36x36 | 실시간 정보 일몰 | ✅ 기존 (`icTwilight`) |
| `icLocalParking` | `ic_local_parking` (918:11937) | 36x36 | 실시간 정보 주차 | ✅ 등록 완료 (PDF) |
| `icPeople` | `ic_people` (518:11945) | 36x36 | 실시간 정보 혼잡도 | ✅ 등록 완료 (PDF) |
| `icHelpOutline` | `ic_help_outline` | 20x20 | 혼잡도 ? 버튼 | ✅ 등록 완료 (PDF) |
| `icErrorOutline` | `ic_error_outline` (189:2248) | 16x16 | 신고 버튼 | ✅ 등록 완료 (PDF) |

> - [x] `icLocalParking`, `icPeople`, `icErrorOutline` export 완료 및 `Assets.xcassets` 등록
> - [x] `icHelpOutline` (20x20) export 및 등록
> - [x] NavBar 관련 아이콘 (`icArrowBackIos`, `icShare`, `icClose`, `icLocationOn`, `icNearMe`) export 및 등록
> - [ ] `icSunny`, `icTwilight` 기존 에셋 사이즈(36x36) Figma와 일치 확인
> - [ ] 위 완료 후 Phase A 진입

### 9.3 타이포 매핑 (사용한 토큰만)

| 사용처 | 토큰 |
|---|---|
| 스팟명 | `.heading(.large)` — Pretendard SemiBold 24pt |
| 북마크 수 / 테마 뱃지 | `.body(.small(.bold))` — 15pt |
| 코멘트 본문 | `.body(.medium())` |
| 실시간 정보 레이블 | `.body(.small(.bold))` gray50 |
| 실시간 정보 값 | `.heading(.large)` gray0 |
| 실시간 정보 보조값 | `.label(.medium)` gray50 |
| 기준 시간 텍스트 | `.body(.small())` gray50 |
| 날짜 뱃지 (이미지 위) | `.body(.small(.bold))` |

---

## 10. TDD A→B→C 오케스트레이션 (Gate 1)

> **A → B → C는 직렬이다. 단계 건너뛰기·병렬화·역순 모두 금지.**

```
§9 에셋 매트릭스 (Gate 4)
        ↓
Phase A — ViewModel TDD (Gate 1A)
  · 진입: §3 API 매핑, §6 ViewModel 시그니처, §9 에셋 매트릭스 모두 확정
  · 작업: reportInvalidInfo() 연동, openSpot() stub, share()/toggleBookmark() 호출 위치 이동 테스트
  · 종료: ViewModel 테스트 100% green, SwiftUI 뷰 파일 미수정
  · 가이드: docs/phases/phase-a-viewmodel-tdd.md ← Phase A 들어갈 때 읽기
        ↓
Phase B — ui-test-cases.md (Gate 1B + Gate 2)
  · 진입: Phase A 종료 조건 통과
  · 작업: docs/KAN-84/ui-test-cases.md 8컬럼 표 작성 (3 케이스 × 각 상태)
  · 종료: TODO 0개, 행마다 스냅샷 파일명 결정
  · 가이드: docs/phases/phase-b-ui-cases.md ← Phase B 들어갈 때 읽기
        ↓
Phase C — Snapshot + UI (Gate 1C + Gate 3)
  · 진입: Phase B 종료 조건 통과
  · 작업: swift-snapshot-testing 케이스 RED → SwiftUI 뷰 수정/신규 → GREEN
  · 종료: 3 케이스 전 스냅샷 green, Figma 비교 루프 1회
  · 가이드: docs/phases/phase-c-snapshot.md ← Phase C 들어갈 때 읽기
```

---

## 11. UI 검증 루프 (Figma 노드별 비교, Phase C 마무리)

Figma MCP 대신 **REST API** 사용: `GET https://api.figma.com/v1/images/LyduUVMjsQi0qyUsENriR5?ids=<nodeId>&format=png&scale=2`

| 컴포넌트 / 케이스 | Figma node-id | 확인 항목 |
|---|---|---|
| 전체 화면 — Default 북마크 OFF | `926:17618` | 섹션 순서, 간격, NavBar 구성 |
| 전체 화면 — Default 북마크 ON | `926:17693` | 북마크 아이콘 ON 상태, 코멘트 길이 대응 |
| 전체 화면 — My스팟 | `926:17963` | MY뱃지, 버튼 레이아웃, 정보 미제공(-) 처리 |
| SpotDetailNavBar | 각 화면 내 Header 노드 | 뒤로가기 위치, 공유/X 아이콘 |
| SpotHeaderSection | `926:17621` (01 기준) | 스팟명, 테마, 북마크수, 코멘트 |
| SpotPhotoSection | `926:17` 내 Frame 634843 | 날짜 뱃지 위치, 주소 행 |
| SpotActionButtons Default | Frame 634774 (01) | 버튼 비율, 북마크 아이콘 크기 |
| SpotActionButtons My스팟 | Frame 634775 (My) | 50/50 레이아웃 |
| SpotRealTimeInfoSection | Frame 634787 (공통) | 아이콘 사이즈, 행 높이, 보조텍스트 정렬 |

---

## 12. 디버그 진입점

기존 `SpotDetailDebugMocks.swift`의 `SpotDetailDebugFixture` 업데이트:
- `bookmarkCount`, `isMine`, `parking` 픽스처 값 추가
- `DebugSpotService` / `DebugBookmarkService` 신규 필드 반영

```swift
// 디버그 진입 (기존 패턴 유지)
Button("스팟 상세 열기") { isSpotDetailPresented = true }
    .fullScreenCover(isPresented: $isSpotDetailPresented) {
        SpotDetailView(viewModel: SpotDetailViewModel(
            spotId: SpotDetailDebugFixture.spot.id,
            spotService: DebugSpotService(),
            bookmarkService: DebugBookmarkService(),
            // ... 나머지 서비스
        ))
    }
```

---

## 13. 논의 포인트

`docs/KAN-84/spot-detail-discussion.md`에 후속 합의 필요 항목 기록.

| # | 항목 | 옵션 |
|---|---|---|
| a | `bookmarkCount` API 미포함 시 | (A) 숨김 처리 (B) 별도 API 추가 요청 |
| b | `isMine` 서버 미지원 시 | (A) 숨김 (B) 로그인 userId 로컬 비교 (보안 취약) → (A) 권고 |
| c | "내 스팟 오픈하기" | 후속 티켓 분리. 이번은 UI만, 탭 시 TODO 토스트 |
| d | "오차 시간" 레이블 | 고정 텍스트인지 `±N분` 값인지 → 피그마 / 기획 확인 |
| e | 뒤로가기 vs X | 둘 다 `dismiss()`? 또는 뒤로가기만 pop? → 화면 진입 방식 확인 |

---

## 14. 마감 체크리스트

**게이트 통과**
- [ ] Gate 1 (TDD A→B→C 직렬): 단계 순서 위반 없음
- [ ] Gate 2 (`ui-test-cases.md`): TODO 0개, 8컬럼 채움
- [ ] Gate 3 (swift-snapshot-testing): 3 케이스 전 green, `__Snapshots__/` PR 첨부, record 블라인드 덮어쓰기 0건
- [ ] Gate 4 (에셋 매트릭스): §9.2 신규 아이콘 8개 등록 완료 후 Phase A 시작했음

**일반**
- [ ] `SWIFT_STRICT_CONCURRENCY: complete` 빌드 경고/에러 0
- [ ] §2 정책 7개 항목 모두 확정 (백엔드 확인 포함)
- [ ] §11 Figma 비교 루프 — 3 케이스 모두 통과
- [ ] §12 디버그 진입점에서 시뮬레이터 3케이스 동작 확인
- [ ] 제거한 4개 컴포넌트 파일에 대한 참조 전체 제거 확인
- [ ] `SpotDetailDebugMocks`, `SpotDetailTestDoubles` 신규 필드 반영
- [ ] `docs/KAN-84/spot-detail-discussion.md` 작성

---

## 15. 작업 순서 요약

```
0. §2 정책 백엔드 확인 → §9 에셋 매트릭스 채움 (Gate 4 — 신규 아이콘 8개 export)
        ↓
1. docs/phases/phase-a-viewmodel-tdd.md 읽기 → Phase A 수행
   주요 작업: reportInvalidInfo() API 연동, openSpot() stub, 기존 테스트 신규 필드 반영
        ↓
2. docs/phases/phase-b-ui-cases.md 읽기 → Phase B 수행
   3 케이스(Default OFF / ON / My스팟) × 상태(loading/loaded/error) 매트릭스
        ↓
3. docs/phases/phase-c-snapshot.md 읽기 → Phase C 수행
   컴포넌트 순서: SpotRealTimeInfoSection → Header → Photo → ActionButtons → NavBar → 전체 조립
        ↓
4. §12 디버그 검증 → §11 Figma 루프 → §13 논의 포인트 → §14 통과 → PR
```
