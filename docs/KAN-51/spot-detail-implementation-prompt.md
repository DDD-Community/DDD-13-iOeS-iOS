# [KAN-51] 스팟 상세 화면 구현 통합 프롬프트

## 0. 작업 컨텍스트 (선결 정보)

**브랜치**: `feature/KAN-51` (이미 develop에서 분기/체크아웃됨)
**티켓**: https://dddios1.atlassian.net/browse/KAN-51
**전체 화면 Figma**: https://www.figma.com/design/0oGEIr4oCzpvj4bkGtE5Oa/DDD-iOeS-%ED%94%BC%EA%B7%B8%EB%A7%88?node-id=686-18705&m=dev

**프로젝트 현재 상태 (재탐색 불필요)**:
- SwiftUI + MVVM, Tuist로 매니페스트 관리(`Project.swift`)
- 외부 의존성: Alamofire, Swinject, KakaoSDK*, nMapsMap, FirebaseMessaging
- 네트워킹: `Pickflow/Sources/Core/Network/{APIEndpoint, NetworkManager}.swift` — Alamofire 래핑, Bearer 토큰 첨부 미구현, base URL 미정
- DI: `AppContainer.shared.registerDependencies()`에서 등록 → `getXxxService()` MainActor 헬퍼로 resolve
- 도메인 서비스: `Pickflow/Sources/Core/Services/{User,Auth,Map,Address,Location}Service.swift` — 대부분 `fatalError("Not implemented")` 스텁
- 기존 화면 패턴 참고: `Pickflow/Sources/Feature/Profile/{ProfileView, ProfileViewModel}.swift`
- 디자인 시스템:
  - 컬러: `Pickflow/Resources/DesignSystem/Colors.xcassets`에 `gray0~gray100`만 존재 → Tuist가 `Derived/Sources/TuistAssets+Pickflow.swift`로 `UIAsset.Colors.grayXX` 자동 생성 → `.foregroundStyle(.gray95)` 식으로 사용
  - 타이포: `Pickflow/Sources/Common/DesignSystem/Fonts/PickflowTypography.swift` — `.pretendard(.heading(.large))` 형태
  - 아이콘: `Assets.xcassets`에 AccentColor/AppIcon만 있음 (신규 아이콘 추가 필요)
- 테스트 타겟 **없음** — 이 PR에서 신설
- `SWIFT_STRICT_CONCURRENCY: complete` 적용 중 → 모든 신규 타입 `Sendable`/`@MainActor` 명시
- Info.plist는 Tuist `AppInfoPlist.swift`에서 생성 — `LSApplicationQueriesSchemes`/URL scheme 변경은 거기서

## 1. 스코프

**구현 범위**:
- 스팟 상세 풀스크린 모달 화면 1개
- 북마크 토글 / 길안내(네이버 지도 + App Store fallback) / 공유(시스템 share sheet + `/share-intents` POST) / "잘못된 정보가 있나요?" 버튼(액션은 TBD)
- 디버그 진입점: `ContentView`에 임시 버튼 두고 하드코딩 `spotId`로 fullScreenCover 띄움
- 테스트 타겟 신설 + `SpotDetailViewModel` 인터랙션 테스트
- 디자인 토큰/아이콘 신규 등록

**범위 밖**:
- "이곳으로 결정" 버튼 (테스트용 UI라 무시)
- Universal Link 생성 (KAN-70에서)
- 잘못된 정보 신고 화면 (TBD)
- 환경별 base URL 분기 (후속)
- 비로그인 분기 (항상 로그인 가정)
- 지도 화면에서의 진입 연결

## 2. 핵심 정책 결정 (사용자 확정)

| # | 항목 | 결정 |
|---|---|---|
| 1 | 일몰 progress bar 윈도우 | **24시간 트랙(00:00~24:00)** 안에서 sunset_time 위치를 비율로 계산. 흰 점 = 일몰 시각의 트랙상 위치, 라벨(PM 6:20) = 흰 점 위에 표시되는 실제 일몰 시각 |
| 2 | 공유 딥링크 | 이번엔 placeholder 텍스트만(예: 스팟명 + 한줄코멘트 + `https://pickflow.app/spot/{id}` 형태 임시 URL). Universal Link는 KAN-70 |
| 3 | 네이버 지도 | `nmap://` URL scheme 호출 + 미설치 시 App Store(`https://apps.apple.com/kr/app/id311867728`) fallback. `LSApplicationQueriesSchemes`에 `nmap` 등록 |
| 4 | 스팟 사진 | 단일 이미지 (`images[0]` 또는 `display_order==0`). `recorded_time`은 첫 이미지 것을 한줄 코멘트 옆 시간 라벨로 |
| 5 | 컬러/아이콘 | Figma hex 직접 추출해서 `Colors.xcassets`에 새 토큰 등록(예: `themeSunset`, `themeReflection`, `sunsetOrange`, `gradientYellow`, `gradientYellowEnd` 등). 아이콘은 Figma SVG export → `Assets.xcassets`에 imageset으로 추가 |
| 6 | 진입점 | `ContentView`에 임시 "Spot Detail 열기" 버튼 + 하드코딩 spotId |
| 7 | 네트워크 인프라 | **(a) 토큰 자동 첨부 인터셉터 + JSONDecoder snake_case 전역 적용까지** 이번 PR에서 같이. 환경별 base URL은 후속 |
| 8 | 거리 | km 가정, 표기 `2.5km` 식. `latitude/longitude` 못 보냈거나 `distance` nil이면 거리 영역 숨김 |
| 9 | 잘못된 정보 신고 버튼 | 버튼만 그리고 onTap은 `// TODO: KAN-?? 후속` |
| 10 | 비로그인 | 항상 로그인 상태 가정. 진입 차단/유도 로직 없음 |

## 3. API 매핑 (스팟 상세 화면이 사용)

| UI 동작 | Endpoint | 비고 |
|---|---|---|
| 화면 진입 시 데이터 로드 | `GET /spots/:id?latitude=&longitude=` | 응답에 `weather`까지 포함되므로 단일 호출로 충분 |
| 북마크 추가 | `POST /bookmarks` body: `{ "spot_id": <id> }` | 409 Conflict는 already-bookmarked로 간주 |
| 북마크 해제 | `DELETE /bookmarks/:spotId` | |
| 공유 의향 기록 | `POST /share-intents` body: `{ "device_id": "<UIDevice.identifierForVendor>" }` | 공유 sheet 띄우기 직전 fire-and-forget(실패해도 사용자에 영향 없음) |

`GET /spots`(목록)와 `POST /spots/:id/reports`(신고)는 이 화면 직접 사용 안 함.

## 4. 신규/수정 파일 목록

**신규**
```
Pickflow/Sources/Core/Network/
  ├── APIBaseURL.swift                       (한 곳에서 base URL 관리, placeholder)
  ├── AuthInterceptor.swift                  (Alamofire RequestInterceptor: Bearer 첨부 + 401 시 refresh 훅 자리)
  └── JSONDecoder+SnakeCase.swift            (전역 디코더)
Pickflow/Sources/Core/Services/Models/
  ├── Spot.swift                             (Spot, SpotDetail, SpotImage, SpotWeather, SpotTheme, Congestion, WeatherCondition)
  └── (필요 시) ShareIntent.swift
Pickflow/Sources/Core/Services/
  ├── SpotService.swift / Protocols/SpotServiceProtocol.swift
  ├── BookmarkService.swift / Protocols/BookmarkServiceProtocol.swift
  └── ShareIntentService.swift / Protocols/ShareIntentServiceProtocol.swift
Pickflow/Sources/Core/Services/Endpoints/
  ├── SpotEndpoint.swift
  ├── BookmarkEndpoint.swift
  └── ShareIntentEndpoint.swift
Pickflow/Sources/Core/Utilities/
  ├── ExternalAppLauncher.swift              (네이버 지도 nmap:// + 앱스토어 fallback, UIApplication.shared 래핑 protocol)
  └── ShareSheetPresenter.swift              (UIActivityViewController 래퍼)
Pickflow/Sources/Feature/SpotDetail/
  ├── SpotDetailView.swift
  ├── SpotDetailViewModel.swift
  └── Components/
      ├── SpotDetailNavBar.swift             (Figma 686-19045)
      ├── SpotHeaderSection.swift            (타이틀/칩/거리 - 686-18968)
      ├── SpotPhotoSection.swift             (대표 사진 - 686-18977)
      ├── SpotActionButtons.swift            (길안내/공유 - 686-18979)
      ├── SpotCommentSection.swift           (한줄코멘트+촬영시각 - 686-18984)
      ├── SpotWeatherSection.swift           (오늘날씨/강수 - 686-18990)
      ├── SpotTempCongestionSection.swift    (현재기온/혼잡도 - 686-18997)
      ├── SunsetTimelineSection.swift        (일몰 영역 전체 - 첨부 이미지 + 686-19007 + 686-19039)
      └── ReportButton.swift                 (잘못된 정보 신고 - 686-19036)
docs/KAN-51/
  └── spot-detail-discussion.md              (논의 포인트)
PickflowTests/
  ├── SpotDetailViewModelTests.swift
  └── Helpers/{MockSpotService, MockBookmarkService, MockShareIntentService, MockExternalAppLauncher, MockShareSheetPresenter}.swift
```

**수정**
- `Project.swift`: 테스트 타겟 추가, (필요 시) `LSApplicationQueriesSchemes` 추가는 `Tuist/ProjectDescriptionHelpers/AppInfoPlist.swift`에서
- `Pickflow/Sources/App/AppContainer.swift`: 신규 서비스 등록, NetworkManager에 인터셉터 주입
- `Pickflow/Sources/Core/Network/NetworkManager.swift`: Session에 interceptor 적용 + decoder 주입
- `Pickflow/Sources/App/ContentView.swift`: 디버그 진입 버튼 + fullScreenCover
- `Pickflow/Resources/DesignSystem/Colors.xcassets`: 신규 컬러 colorset 추가 (Figma hex 추출)
- `Pickflow/Resources/Assets.xcassets`: 신규 아이콘 imageset (해/달/X/공유/길안내/info/카테고리 칩 아이콘 등)
- `Tuist/ProjectDescriptionHelpers/AppInfoPlist.swift`: `LSApplicationQueriesSchemes`에 `nmap` 추가

## 5. 모델 정의 가이드 (응답 매핑)

```swift
struct SpotDetail: Codable, Sendable, Identifiable {
    let id: Int64
    let name: String
    let comment: String
    let theme: SpotTheme
    let latitude: Double
    let longitude: Double
    let distance: Double?               // km, optional
    let address: String
    let images: [SpotImage]
    let isBookmarked: Bool
    let weather: SpotWeather
}
struct SpotImage: Codable, Sendable {
    let imageURL: String
    let displayOrder: Int
    let recordedTime: String            // "19:12"
}
struct SpotWeather: Codable, Sendable {
    let temperature: Int
    let precipitationProbability: Int
    let condition: WeatherCondition
    let sunsetTime: String              // "19:44"
    let congestion: Congestion
}
enum SpotTheme: String, Codable, Sendable { case sunset = "노을", reflection = "윤슬" }
enum WeatherCondition: String, Codable, Sendable { case clear = "맑음", cloudy = "구름 많음", overcast = "흐림", rain = "비", rainSnow = "비/눈", snow = "눈", shower = "소나기" }
enum Congestion: String, Codable, Sendable { case relaxed = "여유", normal = "보통", slightlyCrowded = "약간 붐빔", crowded = "붐빔" }
```

snake_case 디코딩은 **전역 JSONDecoder**에서 `keyDecodingStrategy = .convertFromSnakeCase`로 처리 → 모델엔 CodingKeys 안 박는다.

## 6. ViewModel 상태/액션

```swift
@MainActor
final class SpotDetailViewModel: ObservableObject {
    enum LoadState: Equatable { case idle, loading, loaded(SpotDetail), failed(String) }
    @Published private(set) var state: LoadState = .idle
    @Published private(set) var isBookmarked: Bool = false      // optimistic
    @Published var dismissRequested: Bool = false
    @Published var toast: String? = nil                          // 실패 알림 등

    init(spotId: Int64,
         spotService: SpotServiceProtocol,
         bookmarkService: BookmarkServiceProtocol,
         shareIntentService: ShareIntentServiceProtocol,
         locationService: LocationServiceProtocol,
         externalAppLauncher: ExternalAppLauncherProtocol,
         shareSheetPresenter: ShareSheetPresenterProtocol,
         deviceIdProvider: @Sendable () -> String,
         clock: @Sendable () -> Date = Date.init)

    func onAppear() async                  // 위치 시도 → /spots/:id 호출
    func toggleBookmark() async            // 낙관적 토글 → 실패 시 롤백 + toast
    func openNaverMapsRoute()              // launcher 호출. 미설치면 App Store
    func share()                           // /share-intents 비동기 발사 + share sheet
    func reportInvalidInfo()               // TODO 코멘트
    func close()                           // dismissRequested = true
}
```

clock과 deviceIdProvider 주입은 테스트 가능성을 위함.

## 7. 외부 앱 연동 사양

**네이버 지도**
```
URL: nmap://route/public?dlat={lat}&dlng={lng}&dname={name(percent-encoded)}&appname={bundleId}
canOpenURL("nmap://") false → openURL("https://apps.apple.com/kr/app/id311867728")
```
`appname`은 `Bundle.main.bundleIdentifier`. `LSApplicationQueriesSchemes`에 `nmap` 추가 필수.

**공유**
- `ShareIntentService.recordIntent(deviceId:)` fire-and-forget (`Task { try? await ... }`)
- `ShareSheetPresenter.present(items: [String])`로 시스템 share sheet
- 공유 텍스트 예: `"\(name) - \(comment)\nhttps://pickflow.app/spot/\(id)"` (Universal Link는 KAN-70)

## 8. 일몰 Timeline 구현 사양 (가장 정밀 작업)

- 트랙은 **24시간(00:00 ~ 24:00)** 윈도우
- progress = `(sunsetMinutesFromMidnight) / (24 * 60)` (0.0 ~ 1.0)
- 트랙 컴포넌트 구성:
  - 좌측 끝: 해 아이콘 / 우측 끝: 달 아이콘
  - 점선 점들(decorative dots) — Figma 686-19007 확인하여 점 개수/간격 추출
  - progress 위치에 **흰색 원** 인디케이터
  - 흰색 원 위에 PM/AM 표기 라벨(`themeSunset` 배경 + `sunsetOrange` 텍스트, 예: `PM 6:20`)
  - 트랙 하단: yellow → 어두운 색으로 가는 가로 그라데이션 바 (`LinearGradient(colors: [.gradientYellow, .gradientYellowEnd], startPoint: .leading, endPoint: .trailing)`)
- 라벨이 좌/우 가장자리로 갈 때 화면 밖으로 잘리지 않도록 `.fixedSize()` + offset clamp 처리
- 시간 포맷팅 헬퍼는 `DateFormatter+Extension.swift`에 추가 ("19:44" → "PM 6:20")

## 9. 디자인 시스템 추가

- Figma의 노드별 dev mode에서 컬러 hex/폰트 토큰을 직접 추출해 `Colors.xcassets`에 추가. 후보 네이밍:
  - `themeSunset` (노을 칩 배경/텍스트)
  - `themeReflection` (윤슬 칩 배경/텍스트)
  - `sunsetOrange` (PM 6:20 텍스트)
  - `sunsetOrangeBg` (PM 6:20 pill 배경)
  - `gradientYellow`, `gradientYellowEnd` (일몰 그라데이션 바)
  - `surfaceCard`, `surfaceModal` 등 카드 배경(현재 gray로 안 떨어지는 부분)
- 추가 후 `tuist generate` 시 `UIAsset.Colors`에 자동 추가됨 → `.foregroundStyle(.themeSunset)` 식으로 사용
- 아이콘은 Figma SVG → PDF/PNG export 후 imageset 등록. 코드에서 `Image(UIAsset.Assets.iconSun.rawValue, bundle: PickflowResources.bundle)` 형태로 접근 (또는 자동 생성 활용)

## 10. TDD 작업 순서 (필수)

**테스트 타겟 셋업**
1. `Project.swift`에 두 번째 `.target`으로 `PickflowTests` (product: `.unitTests`, dependencies: `.target(name: "Pickflow")`) 추가
2. `tuist install && tuist generate`로 워크스페이스 갱신 확인
3. `xcodebuild test -workspace Pickflow.xcworkspace -scheme Pickflow -destination 'platform=iOS Simulator,name=iPhone 15'`로 빈 테스트 통과 확인

**TDD 사이클 (각 인터랙션별로 RED → GREEN → REFACTOR)**

작성할 테스트 (우선순위 순):
1. `onAppear_상세조회성공_상태가loaded로전환된다`
2. `onAppear_상세조회실패_상태가failed로전환되고에러메시지가포함된다`
3. `onAppear_위치권한실패시_좌표없이상세조회를호출한다`
4. `toggleBookmark_미북마크상태에서_낙관적으로true가되고_POST가호출된다`
5. `toggleBookmark_API실패시_상태가롤백되고toast가설정된다`
6. `toggleBookmark_409Conflict는성공으로처리된다`
7. `toggleBookmark_북마크상태에서_낙관적으로false가되고_DELETE가호출된다`
8. `openNaverMapsRoute_네이버지도설치되어있으면_nmap스킴URL을연다`
9. `openNaverMapsRoute_네이버지도미설치면_AppStoreURL을연다`
10. `share_share_intents가호출되고_shareSheet가표시된다`
11. `share_share_intents_API실패시에도_shareSheet는표시된다` (fire-and-forget)
12. `close_dismissRequested가true로설정된다`

각 테스트는 **mock 서비스 주입** 기반. `XCTestCase` + async 테스트(`func test_...() async throws`).

각 테스트 작성 → 실패 확인 → 최소 구현 → 통과 → 다음 테스트. **테스트 모두 green 될 때까지 루프**.

마지막에 한 번 `xcodebuild test` 풀로 돌려서 전체 통과 확인.

## 11. UI 검증 루프 (필수)

테스트 그린 + 빌드 성공 후, **컴포넌트별로 Figma node를 한 번 더 확인**하며 다음 체크리스트를 돌리고, 어긋나면 수정 후 다시 검증:

| 컴포넌트 | Figma node-id | 확인 항목 |
|---|---|---|
| Nav bar | 686-19045 | 우측 X 버튼 위치/크기/탭 영역, 배경 |
| 헤더(타이틀/칩/거리) | 686-18968 | 타이포 토큰, 칩 색(노을/윤슬 분기), 거리 포맷, 거리 nil 시 숨김 |
| 사진 | 686-18977 | 비율, 라운딩, 로딩 placeholder |
| 길안내/공유 버튼 | 686-18979 | 레이아웃, 아이콘 정렬, 탭 피드백 |
| 한줄코멘트 + 촬영시각 | 686-18984 | 시각 라벨 위치/포맷, 줄간격 |
| 오늘날씨/강수 | 686-18990 | 날씨 아이콘 매핑(condition별), 강수 % 포맷 |
| 현재기온/혼잡도 | 686-18997 | 기온 단위, 혼잡도 칩 색 |
| 일몰 텍스트 라벨 | 686-19039 | PM/AM 변환, 색상 토큰 |
| 일몰 progress + 그라데이션 | 686-19007 + 첨부 이미지 | 24h 비율 정확성, 점선 점 개수, 인디케이터 위치, 라벨 가장자리 clamp, 그라데이션 방향/색 |
| 잘못된 정보 신고 버튼 | 686-19036 | 위치, 텍스트, onTap은 TODO |

각 노드는 `mcp__claude_ai_Figma__get_design_context` 또는 `get_screenshot`으로 fileKey `0oGEIr4oCzpvj4bkGtE5Oa` + 해당 nodeId로 조회. 어긋남 발견 시 → 수정 → 재확인. **이상 없을 때까지 루프**.

(가능하면 SwiftUI Preview를 컴포넌트별로 작성해 시각 비교 효율을 높일 것)

## 12. 디버그 진입점

`ContentView.swift`에 다음 추가:
```swift
@State private var isSpotDetailPresented = false
private let debugSpotId: Int64 = 1

Button("Spot Detail 열기") { isSpotDetailPresented = true }
    .fullScreenCover(isPresented: $isSpotDetailPresented) {
        SpotDetailView(viewModel: SpotDetailViewModel(spotId: debugSpotId, /* DI resolved */))
    }
```
실제 호출은 mock backend 없으면 실패 → 에러 상태로 보여도 OK. (선택) `SpotService` mock fixture를 DEBUG 빌드에서만 등록하는 옵션 같이 두면 Preview/실기기 둘 다 편함.

## 13. 논의 포인트 MD

`docs/KAN-51/spot-detail-discussion.md` 신규 작성, 다음 포함:

```markdown
# Spot Detail 화면 — 팀 논의 포인트

## 1. 거리 표기 단위 (KAN-51)
- 현재 가정: API `distance: 2.5` = km, UI 표기 `2.5km`
- 1km 미만일 때 m로 환산할지(`750m`), 소수점 자리수 정책, "거리 정보 없음" 노출 여부 합의 필요
- 위치 권한 미허용/좌표 미전달 시 거리 영역은 일단 숨김 처리. 대체 텍스트("위치 권한 필요") 노출 여부 합의 필요

## 2. 비로그인 상태에서 상세 화면 진입 케이스 (KAN-51)
- 현재 가정: 로그인 후에만 진입 가능. 비로그인 분기 미구현.
- 발생 가능 시나리오: 공유 링크/푸시 진입, 로그아웃 후 백그라운드 복귀 등
- 결정 필요: (a) 진입 자체 차단 + 로그인 화면으로 라우팅, (b) 상세 조회는 허용하되 북마크/공유/제보 탭 시 로그인 모달, (c) 기타
- 결정 후 후속 티켓으로 분리 권장
```

## 14. 마감 체크리스트

- [ ] 테스트 타겟 신설 + `xcodebuild test` 그린
- [ ] ViewModel 인터랙션 테스트 12개 모두 통과
- [ ] `SWIFT_STRICT_CONCURRENCY: complete` 빌드 경고/에러 0
- [ ] 각 컴포넌트 Figma 노드 비교 루프 1회 이상 완료
- [ ] 시뮬레이터에서 디버그 진입점으로 fullScreenCover 동작 확인 (네트워크 실패해도 에러 상태 노출 OK)
- [ ] 네이버 지도 미설치 시뮬레이터에서 App Store 폴백 동작
- [ ] `LSApplicationQueriesSchemes`에 `nmap` 등록되어 콘솔 경고 없음
- [ ] `docs/KAN-51/spot-detail-discussion.md` 작성
- [ ] "이곳으로 결정" 버튼은 일체 추가하지 않음 (요구사항 명시)
- [ ] 잘못된 정보 신고 onTap은 `// TODO: KAN-?? 후속`만

## 15. 작업 순서 권고

1. 테스트 타겟 셋업 + 빈 테스트 통과
2. 모델/엔드포인트 정의 + 디코딩 인프라(snake_case + 인터셉터)
3. Mock 기반 ViewModel TDD (테스트 12개)
4. UI 컴포넌트 컴포넌트별 작성 + Preview
5. 화면 조립 + 디버그 진입점
6. 외부 앱 연동(네이버맵/공유) 실기기/시뮬 검증
7. Figma 노드별 비교 루프
8. 논의 포인트 MD 작성
9. 빌드/테스트 풀 회귀
