# [KAN-133] 공지사항 화면 구현 통합 프롬프트

> **이 프롬프트의 사용법**: `screen-tdd-prompt` 스킬이 생성. 이 문서는 **공지사항 리스트 + 상세 두 화면에만 해당하는 사실**(스코프, API, 정책, 에셋, 컴포넌트 매핑)을 담는다.
>
> **방법론은 여기 없다.** TDD 단계별 디테일은 단계 진입 시 리프 문서를 읽는다:
> - Phase A: `docs/phases/phase-a-viewmodel-tdd.md`
> - Phase B: `docs/phases/phase-b-ui-cases.md`
> - Phase C: `docs/phases/phase-c-snapshot.md`

---

## 0. 작업 컨텍스트 (선결 정보)

**브랜치**: `feature/KAN-133` (이미 develop에서 분기/체크아웃됨)
**티켓**: https://dddios1.atlassian.net/browse/KAN-133
**리스트 Figma**: https://www.figma.com/design/0oGEIr4oCzpvj4bkGtE5Oa/?node-id=1084-5706
**상세 Figma**: https://www.figma.com/design/0oGEIr4oCzpvj4bkGtE5Oa/?node-id=1084-5720

**프로젝트 가정 (재탐색 불필요)**:
- SwiftUI + MVVM, Tuist 매니페스트(`Project.swift`)
- 외부 의존성: Alamofire, Swinject, KakaoSDK*, nMapsMap, FirebaseMessaging
- DI: `AppContainer.shared.registerDependencies()` → `getXxxService()` MainActor 헬퍼
- 네트워킹: `NetworkManagerProtocol.request(endpoint:)` → `APIEnvelope<T>` 디코딩. 전역 JSONDecoder `convertFromSnakeCase` 적용 → 모델에 CodingKeys 박지 않음
- 엔드포인트: `enum XxxEndpoint: APIEndpoint`, GET 기본 `URLEncoding.queryString`
- 서비스: `final class XxxService: XxxServiceProtocol, Sendable { init(networkManager:) }` + `Protocols/XxxServiceProtocol.swift`
- 페이징 응답 선례: `SavedSpotPage { spots, page, hasNext }` (`ArchiveService.fetchSavedSpots`)
- 디자인 시스템: `Resources/DesignSystem/Colors.xcassets` → `UIAsset.Colors.grayXX` 자동 생성. 타이포 `.pretendard(...)` 토큰
- 테스트 타겟 `PickflowTests` 존재. 테스트 더블은 `PickflowTests/Helpers/XxxTestDoubles.swift`, 스냅샷은 `XxxSnapshotTests.swift` + `__Snapshots__/`, 환경 헬퍼 `SnapshotEnvironment.swift`
- `SWIFT_STRICT_CONCURRENCY: complete` — 모든 신규 타입 `Sendable`/`@MainActor` 명시
- 선례: KAN-51(`Feature/SpotDetail/*`), KAN-53(`ArchiveService` 페이징)

---

## 1. 스코프

**구현 범위**:
- 공지사항 **리스트** 화면 1개 (페이징 목록 + 빈/로딩/실패 상태)
- 공지사항 **상세** 화면 1개 (제목 + 날짜 + 본문 스크롤 + 로딩/실패 상태)
- 마이프로필 → 공지사항 진입 연결 (`MyProfileSignedInContent` "공지사항" 셀 → push)
- `NoticeService`(목록/상세) + 엔드포인트 + 모델 신규
- `NoticeListViewModel` / `NoticeDetailViewModel` TDD
- swift-snapshot-testing 두 화면 + 상태별

**범위 밖**:
- 공지 작성/수정/삭제 (헤더 우측 "등록"은 Figma에서 opacity 0 placeholder → **그리지 않음**)
- 읽음/안읽음 표시, 뱃지 카운트
- 공지 외 다른 게시판(masterId ≠ 1)
- 푸시 → 특정 공지 딥링크 진입 (후속)
- 본문 리치 텍스트/마크다운/HTML 렌더 (plain text + 줄바꿈 유지만)
- pull-to-refresh (필요 시 후속)

---

## 2. 핵심 정책 결정

| # | 항목 | 결정 |
|---|---|---|
| 1 | 게시판 구분 | `masterId = 1` (공지사항) 상수 고정. ViewModel에 주입(테스트 가능성), 기본값 1 |
| 2 | 페이징 | `page` 0부터, 페이지당 20개(서버), `hasNext` 기반 무한 스크롤. 마지막 행 근접 시 다음 페이지 로드 |
| 3 | 정렬 | 서버가 "고정 공지 최신순 상단" 정렬 → 클라는 응답 순서 그대로 렌더(클라 재정렬 없음) |
| 4 | pinned 시각 강조 | 1차에는 **별도 강조/뱃지 없음** (Figma에 명확한 pinned 마커 없음). 서버 정렬만 신뢰. 강조 필요 여부는 §13 논의 |
| 5 | 리스트 항목 제목 | 최대 **2줄** 표시 후 말줄임(`lineLimit(2)` + `.truncationMode(.tail)`) |
| 6 | 날짜 포맷 | API `"2026-05-09"`(yyyy-MM-dd) → 표시 `"2026.05.09"`. 포맷터는 고정 `Locale(identifier: "en_US_POSIX")`, 파싱 실패 시 원문 그대로 노출 |
| 7 | 상세 본문 | plain text, `\n` 줄바꿈 유지(`.lineSpacing` 적용). 링크/마크다운 파싱 없음 |
| 8 | 탭바 노출 | 마이 탭 `navigationDestination` push → 탭바 유지(기존 `MyProfileView` 패턴 그대로). 별도 숨김 처리 안 함 |
| 9 | 빈 목록 | `items` 비고 `hasNext=false`면 빈 상태 문구 노출(예: "등록된 공지사항이 없어요") |
| 10 | 비로그인 | 항상 로그인 가정. 진입 차단/유도 없음(공지 조회 자체는 인증과 무관할 수 있으나 1차는 기존 인증 헤더 그대로 사용) |

---

## 3. API 매핑

| UI 동작 | Endpoint | 비고 |
|---|---|---|
| 리스트 진입 / 다음 페이지 | `GET /v1/bbs/posts?masterId=1&page={page}` | 응답 `data: { items[], page, hasNext }` |
| 항목 탭 → 상세 | `GET /v1/bbs/posts/{postId}?masterId=1` | 응답 `data: { masterId, postId, title, createdAt, content }` |

**목록 응답**
```json
{ "success": true, "data": { "items": [ { "postId": 0, "title": "string", "createdAt": "2026-06-02", "pinned": true } ], "page": 0, "hasNext": true } }
```
**상세 응답**
```json
{ "success": true, "data": { "masterId": 0, "postId": 0, "title": "string", "createdAt": "2026-06-02", "content": "string" } }
```

---

## 4. 신규/수정 파일 목록

**신규**
```
Pickflow/Sources/Core/Services/Models/
  └── Notice.swift                       (NoticeListItem, NoticePage, NoticeDetail)
Pickflow/Sources/Core/Services/
  └── NoticeService.swift
Pickflow/Sources/Core/Services/Protocols/
  └── NoticeServiceProtocol.swift
Pickflow/Sources/Core/Services/Endpoints/
  └── NoticeEndpoint.swift               (.list / .detail, path "/v1/bbs/posts")
Pickflow/Sources/Feature/Notice/
  ├── NoticeListView.swift
  ├── NoticeListViewModel.swift
  ├── NoticeDetailView.swift
  ├── NoticeDetailViewModel.swift
  └── Components/
      ├── NoticeNavBar.swift             (뒤로가기 + "공지사항" 타이틀 - I1084:5719;1084:7077)
      ├── NoticeRowView.swift            (제목 2줄 + 날짜 - 1084:5709)
      └── NoticeEmptyView.swift          (빈/실패 상태)
docs/KAN-133/
  ├── notice-discussion.md               (§13)
  └── ui-test-cases.md                   (Phase B 산출물)
PickflowTests/
  ├── NoticeListViewModelTests.swift
  ├── NoticeDetailViewModelTests.swift
  ├── NoticeSnapshotTests.swift
  └── Helpers/NoticeTestDoubles.swift    (MockNoticeService)
```

**수정**
- `Pickflow/Sources/App/AppContainer.swift`: `NoticeServiceProtocol` 등록 + `getNoticeService()` 헬퍼(다른 `getXxxService()`와 동일 패턴)
- `Pickflow/Sources/Feature/MyProfile/Components/MyProfileSignedInContent.swift`: "공지사항" 셀 `action`을 빈 클로저 → `onNoticeTap` 콜백으로 연결 (현재 `iconMenuCell(icon: "info.circle", title: "공지사항", action: {})`)
- `Pickflow/Sources/Feature/MyProfile/MyProfileView.swift`: `navigationDestination(isPresented:)`로 `NoticeListView` push (`AccountManagement` 패턴 그대로)
- `Pickflow/Sources/Feature/MyProfile/MyProfileViewModel.swift`: `isNavigatingToNotice` 상태 + `navigateToNotice()` + `noticeService` 보유(또는 `MyProfileView`에서 DI resolve)

---

## 5. 모델 정의 가이드

```swift
import Foundation

struct NoticeListItem: Decodable, Sendable, Identifiable {
    let postId: Int64
    let title: String
    let createdAt: String        // "2026-05-09"
    let pinned: Bool
    var id: Int64 { postId }
}

struct NoticePage: Decodable, Sendable {
    let items: [NoticeListItem]
    let page: Int
    let hasNext: Bool
}

struct NoticeDetail: Decodable, Sendable, Identifiable {
    let masterId: Int64
    let postId: Int64
    let title: String
    let createdAt: String
    let content: String
    var id: Int64 { postId }
}
```

JSONDecoder는 `convertFromSnakeCase` 전역 적용 → CodingKeys 박지 않는다. (필드명이 이미 camelCase라 영향 없음)

**Endpoint**
```swift
import Alamofire
import Foundation

enum NoticeEndpoint: APIEndpoint {
    case list(masterId: Int64, page: Int)
    case detail(postId: Int64, masterId: Int64)

    var baseURL: String { APIBaseURL.current }
    var path: String {
        switch self {
        case .list: "/v1/bbs/posts"
        case let .detail(postId, _): "/v1/bbs/posts/\(postId)"
        }
    }
    var method: HTTPMethod { .get }
    var parameters: Parameters? {
        switch self {
        case let .list(masterId, page): ["masterId": masterId, "page": page]
        case let .detail(_, masterId): ["masterId": masterId]
        }
    }
}
```

**Service**
```swift
protocol NoticeServiceProtocol: Sendable {
    func fetchNotices(masterId: Int64, page: Int) async throws -> NoticePage
    func fetchNoticeDetail(postId: Int64, masterId: Int64) async throws -> NoticeDetail
}

final class NoticeService: NoticeServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol
    init(networkManager: NetworkManagerProtocol) { self.networkManager = networkManager }

    func fetchNotices(masterId: Int64, page: Int) async throws -> NoticePage {
        let envelope: APIEnvelope<NoticePage> = try await networkManager.request(
            endpoint: NoticeEndpoint.list(masterId: masterId, page: page))
        return envelope.data
    }
    func fetchNoticeDetail(postId: Int64, masterId: Int64) async throws -> NoticeDetail {
        let envelope: APIEnvelope<NoticeDetail> = try await networkManager.request(
            endpoint: NoticeEndpoint.detail(postId: postId, masterId: masterId))
        return envelope.data
    }
}
```
> `request` vs `requestJSON` 시그니처는 `ArchiveService`를 그대로 따른다(GET이므로 `request`).

---

## 6. ViewModel 시그니처

```swift
@MainActor
final class NoticeListViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle, loading, loaded([NoticeListItem]), empty, failed(String)
    }
    @Published private(set) var state: LoadState = .idle
    @Published private(set) var isLoadingNextPage = false

    init(noticeService: NoticeServiceProtocol, masterId: Int64 = 1)

    func onAppear() async                                   // 첫 페이지 로드(idle일 때만)
    func loadNextPageIfNeeded(currentItem: NoticeListItem) async  // 마지막 근접 + hasNext + !loading
    func retry() async                                      // failed → 첫 페이지 재로드
}

@MainActor
final class NoticeDetailViewModel: ObservableObject {
    enum LoadState: Equatable { case idle, loading, loaded(NoticeDetail), failed(String) }
    @Published private(set) var state: LoadState = .idle

    init(postId: Int64, noticeService: NoticeServiceProtocol, masterId: Int64 = 1)

    func onAppear() async
    func retry() async
}
```

- 다음 페이지 누적: `loaded` 상태의 배열에 append, 내부에 `currentPage`/`hasNext` 보관
- 빈 응답(첫 페이지 `items` 비고 `hasNext=false`) → `.empty`
- DI: `AppContainer.registerDependencies()`에 `NoticeService` 등록

---

## 7. 외부 앱 / 시스템 연동

해당 없음 (섹션 생략).

---

## 8. 화면별 정밀 사양

**리스트 (1084:5706)**
- 배경 `gray95`(#131416). 컨텐츠 좌우 패딩 16
- 항목 셀: 상하 패딩 24, 내부 `VStack(spacing: 8)` — 제목(`.body(.large())`, `gray0`, `lineLimit(2)`) / 날짜(`.body(.small())`, `gray40`)
- 셀 하단 구분선: `gray90` 1pt bottom border
- 무한 스크롤: 마지막 셀 `onAppear` 또는 `loadNextPageIfNeeded`
- 다음 페이지 로딩 시 하단 `ProgressView`

**상세 (1084:5720)**
- 본문 영역 배경 `gray90`(#1e2124) (리스트와 다름 주의), 좌우 패딩 16
- 상단 블록(제목+날짜): `VStack(spacing: 12)`, 상하 패딩 12, 하단 구분선 `gray80`
  - 제목 `.body(.large())` `gray0` (줄 수 제한 없음, 전체 노출)
  - 날짜 `.body(.small())` `gray40`
- 본문: `.body(.medium())` `gray30`, `\n` 유지, `.lineSpacing(...)`, 상하 패딩 12
- 전체 `ScrollView`

**공통 네비바 (NoticeNavBar)**
- 높이 48, 좌측 뒤로가기 버튼, 중앙 타이틀 "공지사항" `.heading(.medium)`(22 SemiBold) `gray0`
- 우측 "등록" placeholder는 **그리지 않음**(투명 영역) — 중앙 정렬 균형이 필요하면 좌측 버튼 폭만큼 빈 spacer
- 뒤로가기: `@Environment(\.dismiss)` 또는 콜백. `AccountManagementView.customHeader` 패턴 참고

---

## 9. 디자인 시스템 추가 — **에셋 입력 매트릭스 (Gate 4)**

> 이 매트릭스가 모두 채워진 다음에야 §10 Phase A를 시작한다.

### 9.1 컬러 매트릭스

| 토큰명 | Figma 표기 | hex | 용도 | 신규? |
|---|---|---|---|---|
| `gray95` | color/dark/gray95 | #131416 | 리스트 배경 | 기존 |
| `gray90` | color/dark/gray90 | #1e2124 | 상세 본문 배경 / 리스트 구분선 | 기존 |
| `gray80` | color/dark/gray80 | #33363d | 상세 상단 블록 구분선 | 기존 |
| `gray40` | color/dark/gray40 | #8a949e | 날짜 텍스트 | 기존 |
| `gray30` | color/dark/gray30 | #b1b8be | 상세 본문 텍스트 | 기존 |
| `gray0` | color/dark/gray0 | #ffffff | 제목/타이틀 텍스트 | 기존 |

> **신규 컬러 토큰 0개.** 모두 기존 `UIAsset.Colors.grayXX` 사용. `tuist generate` 불필요(컬러 측면).

### 9.2 아이콘/이미지 매트릭스

| 에셋명 | Figma node | 처리 | 비고 |
|---|---|---|---|
| 뒤로가기 화살표 | ic_arrow_back_ios (I1084:5719;1084:7079) | **기존 `icon_back_arrow` 에셋 재사용** | `Assets.xcassets/icon_back_arrow.imageset` 존재. `SpotSearchView.headerView` 패턴(`AssetImage(named:"icon_back_arrow", renderingMode:.template, size:28)` + `chevron.left` 폴백) 그대로 사용. **신규 에셋 0개** |

> **확정**: `SpotSearchView` 네비바가 공지사항 네비바와 동일 구성(`.heading(.medium)` 타이틀, height 48, gray95) → 그대로 차용. 신규 imageset 불필요.

### 9.3 타이포 매핑

| 사용처 | Figma 스타일 | 토큰 |
|---|---|---|
| 네비 타이틀 "공지사항" | Heading/medium (22 SemiBold) | `.pretendard(.heading(.medium))` |
| 리스트 제목 / 상세 제목 | Body/large (17 Regular) | `.pretendard(.body(.large()))` |
| 날짜 | Body/small (13 Regular) | `.pretendard(.body(.small()))` |
| 상세 본문 | Body/medium (15 Regular) | `.pretendard(.body(.medium()))` |

> 매트릭스 채움 자가 점검:
> - [x] §9.1 채움 (신규 0, 전부 기존 토큰)
> - [x] §9.2 뒤로가기 아이콘 방식 확정 (`icon_back_arrow` 재사용, 신규 0)
> - [x] §9.3 타이포 토큰 확정

§9.2 확정 완료 → Phase A 진입 가능.

---

## 10. TDD A→B→C 오케스트레이션 (Gate 1)

> **A → B → C는 직렬이다. 단계 건너뛰기·병렬화·역순 금지.**

```
§9 에셋 매트릭스 (Gate 4) — §9.2 아이콘 방식 확정
        ↓
Phase A — ViewModel TDD (Gate 1A)
  · 진입: §3, §6, §9 확정
  · 작업: NoticeListViewModel / NoticeDetailViewModel 인터랙션별 RED → GREEN, SwiftUI 뷰 0줄
  · 종료: ViewModel 테스트 100% green, 뷰 파일 0개
  · 가이드: docs/phases/phase-a-viewmodel-tdd.md ← Phase A 들어갈 때 읽기
        ↓
Phase B — ui-test-cases.md (Gate 1B + Gate 2)
  · 진입: Phase A 종료 조건 통과
  · 작업: docs/KAN-133/ui-test-cases.md 8컬럼 표 작성(두 화면 × 상태)
  · 종료: TODO 0개, 행마다 스냅샷 파일명 결정
  · 가이드: docs/phases/phase-b-ui-cases.md ← Phase B 들어갈 때 읽기
        ↓
Phase C — Snapshot + UI (Gate 1C + Gate 3)
  · 진입: Phase B 종료 조건 통과
  · 작업: NoticeSnapshotTests RED → SwiftUI 뷰 → GREEN
  · 종료: 매트릭스 전 케이스 green, §11 Figma 비교 루프 1회
  · 가이드: docs/phases/phase-c-snapshot.md ← Phase C 들어갈 때 읽기
```

> 각 Phase에 **들어갈 때** 해당 리프 문서를 read한다. 미리 다 읽어두지 않는다.

---

## 11. UI 검증 루프 (Figma 노드별 비교, Phase C 마무리)

| 컴포넌트 | Figma node-id | 확인 항목 |
|---|---|---|
| 네비바 | I1084:5719;1084:7077 | 뒤로가기 위치/탭영역, 타이틀 폰트·중앙정렬, 우측 "등록" 안 그림 |
| 리스트 항목 셀 | 1084:5709 | 제목 2줄 말줄임, 날짜 포맷/색, 구분선(gray90), 패딩 24 |
| 리스트 전체 | 1084:5706 | 배경 gray95, 좌우 16, 빈/로딩 상태 |
| 상세 상단 블록 | 1084:5723 | 제목 전체노출, 날짜, 구분선(gray80), 배경 gray90 |
| 상세 본문 | 1084:5726 / 1084:5727 | 본문 색(gray30), 줄바꿈 유지, lineSpacing |

각 노드 조회: `mcp__claude_ai_Figma__get_design_context` / `get_screenshot` (fileKey `0oGEIr4oCzpvj4bkGtE5Oa`).

---

## 12. 디버그 진입점

실제 진입점은 마이프로필 "공지사항" 셀이지만, 단독 검증용으로 `ContentView`에 임시 버튼:
```swift
@State private var isNoticePresented = false

Button("공지사항 열기") { isNoticePresented = true }
    .fullScreenCover(isPresented: $isNoticePresented) {
        NavigationStack {
            NoticeListView(viewModel: NoticeListViewModel(noticeService: AppContainer.shared.getNoticeService()))
        }
    }
```
네트워크 실패 시 `.failed` 상태로 보여도 OK.

---

## 13. 논의 포인트 MD

`docs/KAN-133/notice-discussion.md` — 다음 포함:
- (a) **pinned 시각 강조**: Figma 첫 항목만 흰색/나머지 회색인데, 이게 (1) pinned 강조인지 (2) 읽음/안읽음인지 (3) 단순 시안 노이즈인지 불명. 1차는 강조 없이 서버 정렬만. 강조 필요 시 토큰·배지 후속 합의.
- (b) **본문 포맷**: plain text 가정. 서버가 추후 마크다운/HTML 내려줄 가능성 → 렌더 전략 합의 필요.
- (c) **pull-to-refresh / 신규 공지 뱃지**: 1차 범위 밖. 필요 여부 합의.

---

## 14. 마감 체크리스트

**게이트 통과**
- [x] Gate 1 (TDD A→B→C 직렬): 단계 순서 위반 없음 (A: VM 테스트 → B: ui-test-cases → C: 스냅샷+뷰)
- [x] Gate 2 (`ui-test-cases.md`): TODO 0개, 8컬럼 채움
- [x] Gate 3 (swift-snapshot-testing): Notice 20케이스 green, `__Snapshots__/NoticeSnapshotTests/` 20장 기록, 1회 record 후 OFF (블라인드 덮어쓰기 0건)
- [x] Gate 4 (에셋 매트릭스): §9.2 아이콘 방식 확정 후 Phase A 시작 (신규 컬러/아이콘 0개)

**일반**
- [x] `SWIFT_STRICT_CONCURRENCY: complete` 빌드 경고/에러 0 (전체 앱 타겟 컴파일 + 테스트 실행 성공)
- [x] §11 Figma 비교 루프 1회 (리스트 loaded/longtitle, 상세 long, failed 스냅샷 vs Figma 노드 대조 완료)
- [ ] 마이프로필 "공지사항" 셀 → 리스트 → 상세 push 시뮬레이터 실기동 확인 (코드 연결 완료, 실 네트워크 검증은 백엔드 연동 후)
- [x] 빈 목록 / 로드 실패 / 다음 페이지 로딩 상태 (스냅샷 + VM 테스트로 커버)
- [x] `docs/KAN-133/notice-discussion.md` 작성

> 참고: 전체 테스트 스위트에는 KAN-133 무관한 사전 존재 스냅샷 실패(SpotDetail/SpotList/MyProfile 등 — baseline이 iPhone 15에서 기록, 현재 iPhone 17/iOS26 렌더 차이)가 있음. 내가 건드리지 않은 `test_my_profile_signedout_*`도 동일하게 실패하는 것이 환경 이슈의 증거. Notice 신규 스냅샷은 iPhone 17에서 기록되어 green.

---

## 15. 작업 순서 요약

```
0. §0~§8 합의 → §9.2 뒤로가기 아이콘 방식 확정 (Gate 4)
        ↓
1. 모델/엔드포인트/서비스 + AppContainer 등록
        ↓
2. docs/phases/phase-a-viewmodel-tdd.md 읽기 → Phase A (List/Detail VM TDD) (Gate 1A)
        ↓
3. docs/phases/phase-b-ui-cases.md 읽기 → Phase B (ui-test-cases.md) (Gate 1B + 2)
        ↓
4. docs/phases/phase-c-snapshot.md 읽기 → Phase C (스냅샷 + 뷰 + 마이프로필 연결) (Gate 1C + 3) → §11 Figma 루프
        ↓
5. §12 디버그 검증 → §13 논의 포인트 → §14 통과 → PR
```
