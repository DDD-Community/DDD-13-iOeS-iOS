# [KAN-55] 스팟 등록 화면 구현 — 통합 프롬프트

> 이 문서는 Claude / Codex 같은 AI 에이전트에게 KAN-55 작업을 한 번에 지시하기 위한 통합 프롬프트다.
> 아래 내용을 그대로 복사해서 에이전트 프롬프트로 사용하면 된다.
> 선행 티켓 **KAN-46**(로그인 진입 화면)의 레이어·컨벤션·DI 패턴을 그대로 따른다. 참고: `docs/KAN-46/prompt.md`, `docs/KAN-46/implementation.md`.

---

## 0. 역할 지시 (System / Role)

너는 `Pickflow` iOS 앱의 시니어 iOS 엔지니어다.
프로젝트의 `AGENTS.md`와 레이어 규칙(App → Feature → Common → Core)을 준수하고,
Swift 6 + SwiftUI + Swift Concurrency 스타일로 깔끔한 코드를 작성한다.
모든 코드는 컴파일 가능한 완전한 형태로 제시하고, 새 파일은 정확한 절대 경로와 함께 제공한다.

---

## 1. 티켓 개요

- **Jira Key**: KAN-55
- **Feature 브랜치**: `feature/KAN-55` (develop 기준, 이미 생성됨)
- **목표**: 사용자가 자신이 찍은 스팟 사진·장소·카테고리·촬영시각·코멘트를 입력해 **스팟을 서버에 등록**하는 "스팟 등록" 화면(`SpotRegistrationView`)을 구현한다.
- **핵심 CTA**: 우상단 `등록` 버튼. 필수 입력이 충족되면 활성화되고, 탭 시 등록 API(스텁) 호출 → 성공 시 스팟 상세 화면으로 `push` 이동.
- **네비게이션**: 현재는 진입점이 없으므로 `ContentView`를 `NavigationStack`으로 만들고 "스팟 등록 열기" 링크로 push 하도록 배선한다. 실제 진입점(지도/리스트 화면 플러스 버튼 등)은 후속 티켓 범위.

---

## 2. 화면 스펙 (디자인 명세)

기준 스크린샷: Figma `3.2 스팟 등록` 상태 3종 + 날짜 선택 bottomsheet(`Frame 634799`) + 시간 선택 bottomsheet(`Frame 634798`).

### 2.1. 공통

- 배경: 거의 블랙 (`#0B0B0B` 근처). 화면 전체 스크롤 가능(`ScrollView` 루트).
- 카드/필드 배경: 다크 그레이 (`#1C1C1E` 근처). 코너 라운드 12–16pt.
- 텍스트: 주요 화이트, 보조/플레이스홀더 라이트 그레이 (`#8A8A8E` 근처).
- 포인트 컬러(오렌지): `#FF6A2A` 근처 (카카오 옐로우 아님 주의).
- 폰트는 항상 `pretendard(...)` 토큰 사용, 하드코딩 `.font(.system(size:))` 금지.
- 섹션 라벨은 `.pretendard(.body(.medium()))` 또는 `.body(.medium(.bold))`, 본문은 `.body(.large())`, 보조설명은 `.body(.small())` 기준 (디자인 토큰 내에서 최적 매핑 선택).

### 2.2. 네비게이션 바

- 좌: 시스템 뒤로 `chevron.left` (푸시 네비게이션 기본, `toolbarRole(.editor)` 또는 custom back)
- 중: 제목 `스팟 등록` (`.pretendard(.heading(.small))`)
- 우: `등록` 버튼
  - 비활성: 회색 (`#5A5A5A` 근처)
  - 활성: 오렌지 (`#FF6A2A`)
  - 활성화 조건은 §2.11 참고
  - 로딩 중: 텍스트 자리에 스피너(`ProgressView()`)

### 2.3. 사진 등록 카드 (상단)

- 높이: 약 180pt, 좌우 20pt 마진, 코너 16pt
- 빈 상태: 중앙 아이콘(`photo.badge.plus` SF Symbol) + 2줄 텍스트 `등록할 스팟의 사진을\n선택해 주세요.`
- 선택 후: 이미지로 카드 가득 채움 (`.scaledToFill()` + clip). 우측 상단 작은 `xmark.circle.fill` 등으로 제거 버튼 제공.
- 탭: `PhotosPicker`(단일 이미지, **갤러리만**) 띄움. 카메라 촬영은 **범위 외**.
- 사진은 현재 티켓에서 **업로드하지 않는다**(서버 스펙 미정). `Data`로 보관만 하고, 실제 업로드는 `TODO(BE-API): 업로드 방식 확정 후`.
- **필수 필드**(§2.11).

### 2.4. 주소 카드

- 상태 A (선택 전): 카드 숨김 처리 (디자인에 빈 상태 표기 없음)
- 상태 B (선택 후): 다크 그레이 카드
  - 타이틀: `잠원 한강공원` (`.pretendard(.body(.large(.bold)))`)
  - 서브: `서울 서초구 잠원로 221-124 잠원한강공원` (`.pretendard(.body(.small()))`, gray)
  - 거리 pill: `2.5km` — 다크 배경 캡슐, `.pretendard(.label(.small))`, 현재 위치 기반 계산(후속 티켓에서 실제 연동 — 현재는 Mock 값 허용)

### 2.5. "장소 검색하기" 버튼

- 풀폭, 높이 52–56pt, 코너 16pt
- 배경: 오렌지 `#FF6A2A`, 텍스트 흰색 `.pretendard(.body(.large(.bold)))`
- 콘텐츠: `mappin` SF Symbol + `장소 검색하기`
- 탭 동작: **현재 티켓에서는 no-op** — `// TODO(KAN-XX): 주소 검색 화면 연결`. 개발 편의를 위해 `#if DEBUG` 하위에 "Mock 주소 주입" 경로(long-press 등) 하나 남겨 QA 가능하게 한다.

### 2.6. 스팟 이름 섹션

- 라벨: `스팟 이름`
- TextField 한 줄:
  - placeholder: `스팟 이름을 입력해 주세요.`
  - 최대 20자. 초과 입력 시 잘라냄 (ViewModel에서 clamp).
  - 우측 카운터 `{count}/20` (`.pretendard(.label(.small))`, 회색)
- 카드 배경(다크 그레이), 좌우 패딩 16pt, 높이 48pt
- **필수 필드**(trim 후 1자 이상, §2.11).

### 2.7. 사진 카테고리 섹션

- 라벨: `사진 카테고리`
- 가로 나열 chip 2개 — 단일 선택 (radio). 같은 chip 재탭 시 선택 해제 허용.
  - `🌇 노을` (`sunset` — **TODO(BE-API)**: enum 키 확정 필요, §9)
  - `🌊 윤슬` (`reflection` — **TODO(BE-API)**)
- Chip 상태:
  - Unselected: 다크 그레이 배경, 흰 텍스트
  - Selected: 오렌지 보더(1.5pt) — 디자이너 확정 전까지 보더 방식 기본값
- 아이콘은 이모지 사용. PNG 에셋이 나오면 교체 가능하도록 `PhotoCategory.iconEmoji` 수준으로 추상화.
- **선택 필드**(§2.11).

### 2.8. 촬영 기록 정보 섹션

- 라벨: `촬영 기록 정보`
- 가로 2열 필드:
  - **날짜 필드** (좌)
    - 미선택: placeholder `날짜 선택` 회색
    - 선택 후: `4월 11일 토` 형식 (`M월 d일 EEE`, 로케일 `ko_KR`) 흰색 + 우측 오렌지 `수정` 뱃지
  - **시간 필드** (우)
    - 미선택: placeholder `시간 선택` 회색
    - 선택 후: `오후 6:33` 형식 (`a h:mm`, 로케일 `ko_KR`) + 오렌지 `수정` 뱃지
- 각 필드 탭 시 하단 `sheet`로 **Date Picker / Time Picker BottomSheet** 제시 (§2.9)
- 날짜/시간 모두 **오늘 · 현재 시각 이하만 허용**. 미래 시점 선택 불가.
  - 날짜가 오늘인 경우 시간 picker 허용 상한 = `now`.
  - 날짜가 오늘 이전이면 시간 범위 제한 없음(23:59까지).
- **필수 필드**(둘 다, §2.11).

### 2.9. Date / Time Picker BottomSheet

SwiftUI `sheet(isPresented:)` + `.presentationDetents([.height(360)])`, `.presentationDragIndicator(.visible)`.

- 다크 배경 (`#1C1C1E`), 코너 상단만 라운드(시스템 기본).
- 상단 타이틀 중앙: `날짜 선택` / `시간 선택` (`.pretendard(.body(.large(.bold)))`)
- 중앙: **3열 wheel picker** — MVP는 SwiftUI `Picker(selection:) { ForEach }`를 `.pickerStyle(.wheel)`로 가로 배치.
  - 날짜: `[년][월][일]` — 각 열 독립 Picker, 셀렉션 변경 시 year/month 기준 day 범위 재계산.
  - 시간: `[오전/오후][시(1–12)][분(0–59)]`
- 픽셀 레벨 시안 일치(셀렉션 캡슐 하이라이트 등)는 **후속 과제** — `// TODO(design-polish): 커스텀 wheel 스타일` 주석 남김.
- 하단: 풀폭 오렌지 `확인` 버튼 — 탭 시 ViewModel에 값 반영 + sheet dismiss.
- 초기값: 이미 선택된 값이 있으면 그 값, 없으면 **현재 시각** 기준 값.
- 허용 범위: 상한 = `Date()` (열릴 때의 "현재"). 하한 = 편의상 2000-01-01.
- `확인` 버튼이 없어도 dismiss되면 값 반영 안 됨(`온 확인` 탭에서만 반영).

### 2.10. 한 줄 코멘트 섹션

- 라벨: `한 줄 코멘트`
- `TextField(axis: .vertical)` (iOS 26) 또는 `TextEditor`
  - placeholder: `스팟에 대한 한 줄 코멘트를 남겨주세요.`
  - 최대 50자, 초과 시 잘라냄
  - 우측 하단 카운터 `{count}/50`
  - 높이: 최소 96pt
- **선택 필드**(§2.11).

### 2.11. 등록 버튼 활성화 조건

**필수 (모두 충족 시 활성화)**:
- ✅ 사진 선택됨 (`photoData != nil`)
- ✅ 스팟 이름 입력됨 (`spotName.trimmingCharacters(.whitespacesAndNewlines).isEmpty == false`)
- ✅ 주소 선택됨 (`selectedAddress != nil`)
- ✅ 촬영 날짜 선택됨 (`capturedDate != nil`)
- ✅ 촬영 시간 선택됨 (`capturedTime != nil`)

**선택(없어도 활성화)**: 카테고리, 한 줄 코멘트

> 현재는 5개 모두 필수. 운영 중 정책 변경 가능성 있으니 `SpotRegistrationViewModel.isRegisterEnabled` 한 곳에서 규칙을 정의해 수정 용이성을 확보한다.

### 2.12. 제출 플로우

1. `등록` 탭 → `ViewModel.submit()` 실행
2. `isSubmitting = true` → 우상단 스피너, 버튼 비활성
3. `SpotService.registerSpot(draft:)` **stub** 호출 (§5 참고)
4. 성공 시: `NavigationStack`의 `NavigationPath`에 `SpotId` push → `SpotDetailPlaceholderView(spotId:)`. 실제 상세 화면은 후속 티켓. placeholder는 `Text("Spot Detail (WIP) - id: \(id.rawValue)")` 허용.
5. 실패 시: `errorMessage` 세팅 → 시안 확정 전까지 `.alert("등록 실패", isPresented:)`로 표시. (TODO: 토스트 시스템 도입 시 교체)

### 2.13. 접근성

- 모든 입력 카드에 `accessibilityLabel` 부여 (예: 사진 카드 — "스팟 사진 선택")
- `등록` 버튼: `accessibilityHint("입력한 내용으로 스팟을 등록합니다")`
- 카운터: `accessibilityLabel("{count}자, 최대 {max}자")`
- Dynamic Type 대응을 위해 `pretendard(...)` 토큰만.

---

## 3. 아키텍처 & 파일 구조

### 3.1. 신규 파일 (Feature)

```
Pickflow/Sources/Feature/SpotRegistration/
├── SpotRegistrationAssembly.swift      # DI 팩토리
├── SpotRegistrationModels.swift        # Feature-local 보조 타입 (카테고리 프리젠테이션 등)
├── SpotRegistrationView.swift          # 루트 View
├── SpotRegistrationViewModel.swift     # @MainActor ObservableObject
├── SpotDetailPlaceholderView.swift     # 등록 성공 후 이동할 임시 상세 placeholder
└── Components/
    ├── SpotPhotoPickerCard.swift       # 사진 카드 (PhotosPicker 래핑, 단일/갤러리)
    ├── SpotAddressCard.swift           # 선택된 주소 표시 카드
    ├── SpotSearchLocationButton.swift  # "장소 검색하기" 오렌지 버튼
    ├── LabeledSection.swift            # 섹션 라벨 + 내용 래퍼
    ├── CountedTextField.swift          # 카운터 포함 한 줄 TextField
    ├── CountedTextEditor.swift         # 카운터 포함 멀티라인 Editor
    ├── PhotoCategoryChipGroup.swift    # 노을/윤슬 chip 그룹
    ├── CaptureDateTimeRow.swift        # 날짜/시간 2열 row
    ├── CaptureDatePickerSheet.swift    # 날짜 wheel bottomsheet
    └── CaptureTimePickerSheet.swift    # 시간 wheel bottomsheet
```

> 컴포넌트를 `Common/Components/`가 아닌 `Feature/SpotRegistration/Components/`에 두는 이유: 현재 재사용 범위가 이 화면에 한정. 다른 Feature에서도 쓰이기 시작하면 그때 `Common/Components`로 승격. (KAN-46과 동일 기조)

### 3.2. 신규 Service (Core) — **스텁만**

> BE 스펙이 아직 준비되지 않음. 프로토콜 + 스텁 구현까지만 생성. 엔드포인트/DTO는 가짜값으로 채우고 `TODO(BE-API)` 로 명시.

```
Pickflow/Sources/Core/Services/
├── SpotService.swift                       # 스텁 구현
└── Protocols/
    └── SpotServiceProtocol.swift           # 프로토콜 + SpotRegistrationDraft, SpotId, PhotoCategory
```

```swift
protocol SpotServiceProtocol: Sendable {
    /// 스팟을 서버에 등록한다.
    /// - TODO(BE-API): 요청/응답 스키마 확정 시 draft → 실제 DTO 매핑. 이미지 업로드 방식(multipart vs presigned URL)도 확정 필요.
    func registerSpot(draft: SpotRegistrationDraft) async throws -> SpotId
}

struct SpotRegistrationDraft: Sendable {
    let photoData: Data              // 필수
    let address: Address             // Core/Services/Protocols/AddressServiceProtocol.Address 재사용
    let spotName: String             // 필수, trim 완료된 상태
    let category: PhotoCategory?
    let capturedAt: Date             // 날짜(YMD) + 시간(HM) 병합
    let comment: String?             // trim 후 빈문자열이면 nil
}

struct SpotId: Hashable, Sendable {
    let rawValue: String
}

enum PhotoCategory: String, CaseIterable, Sendable, Hashable {
    case sunset       // TODO(BE-API): 실제 enum 키 확인
    case reflection   // TODO(BE-API)
}
```

`SpotService` 스텁:

```swift
final class SpotService: SpotServiceProtocol, Sendable {
    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    func registerSpot(draft: SpotRegistrationDraft) async throws -> SpotId {
        // TODO(BE-API): 실제 네트워크 호출로 교체
        try await Task.sleep(for: .seconds(1))
        return SpotId(rawValue: UUID().uuidString)
    }
}
```

### 3.3. AppContainer 등록

`App/AppContainer.swift`의 `registerDependencies()`에 추가:

```swift
container.register(SpotServiceProtocol.self) { SpotService(networkManager: networkManager) }
```

> 현재 스텁이 `networkManager`를 쓰지 않더라도 시그니처를 미리 맞춰 두어 실연동 시 수정 폭을 줄인다.

### 3.4. NavigationStack 배선

`App/ContentView.swift`(현재 `Text("Pickflow")`)를 `NavigationStack`으로 변경:

```swift
struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Pickflow")
                    .font(.largeTitle)
                NavigationLink("스팟 등록 열기") {
                    SpotRegistrationAssembly.make()
                }
            }
        }
    }
}
```

`SpotRegistrationAssembly.make()`가 DI 해결 담당:

```swift
@MainActor
enum SpotRegistrationAssembly {
    static func make() -> some View {
        let spotService: SpotServiceProtocol = AppContainer.shared.container.resolve(SpotServiceProtocol.self)!
        return SpotRegistrationView(
            viewModel: SpotRegistrationViewModel(spotService: spotService)
        )
    }
}
```

등록 성공 시 `SpotRegistrationView` 내부에서 `@State var path: [SpotId]` 또는 `NavigationPath`에 push → `SpotDetailPlaceholderView(spotId:)` 표시. (ContentView의 루트 NavigationStack을 쓰려면 path를 ContentView로 끌어올리는 대신, SpotRegistrationView 자체가 하위 `navigationDestination(for: SpotId.self)`를 등록해 이 스택을 활용하는 방식으로 간소화 가능 — 정답은 구현자가 선택.)

### 3.5. ViewModel 설계 (`SpotRegistrationViewModel`)

```swift
@MainActor
final class SpotRegistrationViewModel: ObservableObject {
    // Inputs
    @Published var photoData: Data?
    @Published var selectedAddress: Address?
    @Published var spotName: String = ""
    @Published var category: PhotoCategory?
    @Published var capturedDate: Date?
    @Published var capturedTime: Date?
    @Published var comment: String = ""

    // Outputs
    @Published private(set) var isSubmitting = false
    @Published var errorMessage: String?
    @Published private(set) var registeredSpotId: SpotId?

    private let spotService: SpotServiceProtocol

    init(spotService: SpotServiceProtocol) {
        self.spotService = spotService
    }

    var isRegisterEnabled: Bool {
        photoData != nil
            && !spotName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && selectedAddress != nil
            && capturedDate != nil
            && capturedTime != nil
            && !isSubmitting
    }

    var spotNameCount: Int { spotName.count }
    var commentCount: Int { comment.count }

    func setSpotName(_ value: String) {
        spotName = String(value.prefix(20))
    }

    func setComment(_ value: String) {
        comment = String(value.prefix(50))
    }

    func submit() async {
        guard isRegisterEnabled else { return }
        guard let photoData,
              let address = selectedAddress,
              let date = capturedDate,
              let time = capturedTime else { return }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let capturedAt = Self.mergeDateAndTime(date: date, time: time)
        let trimmedName = spotName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)

        let draft = SpotRegistrationDraft(
            photoData: photoData,
            address: address,
            spotName: trimmedName,
            category: category,
            capturedAt: capturedAt,
            comment: trimmedComment.isEmpty ? nil : trimmedComment
        )

        do {
            registeredSpotId = try await spotService.registerSpot(draft: draft)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func mergeDateAndTime(date: Date, time: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let d = cal.dateComponents([.year, .month, .day], from: date)
        let t = cal.dateComponents([.hour, .minute], from: time)
        var merged = DateComponents()
        merged.year = d.year; merged.month = d.month; merged.day = d.day
        merged.hour = t.hour; merged.minute = t.minute
        return cal.date(from: merged) ?? date
    }
}
```

### 3.6. View ↔ ViewModel 주입

- `SpotRegistrationView`: `@StateObject var viewModel: SpotRegistrationViewModel`를 외부 주입(= `ProfileView` 패턴).
- `SpotRegistrationAssembly.make()`가 DI 해결 담당.

---

## 4. 구현 요구사항 체크리스트

- [ ] `feature/KAN-55` 브랜치에서 작업
- [ ] §3.1 신규 파일 전체(View/VM/Assembly/Models/Placeholder + Components 10개) 생성
- [ ] §3.2 Service 스텁 + 프로토콜 생성
- [ ] `AppContainer.registerDependencies()`에 `SpotServiceProtocol` 등록 (AGENTS.md 필수 규칙)
- [ ] `ContentView`에 `NavigationStack` + 스팟 등록 진입 링크 배선
- [ ] 모든 폰트는 `pretendard(...)` 토큰 사용, 하드코딩 금지
- [ ] 컬러는 매직넘버 대신 `private extension Color`로 네임드 상수화 (예: `static let spotOrange = Color(red: 1.0, green: 0.416, blue: 0.165)`)
- [ ] `등록` 버튼 활성화 규칙(§2.11) 준수 + 로딩 스피너
- [ ] 날짜/시간 picker의 **미래 시점 차단** 로직 포함 (오늘·현재시각 이하만)
- [ ] 사진 단일 선택(`PhotosPicker`, `matching: .images`), 제거 버튼
- [ ] 스팟 이름 20자 / 코멘트 50자 **clamp** (ViewModel setter에서 초과 입력 차단)
- [ ] `#Preview`: `SpotRegistrationView` 단독 프리뷰 (Mock Service로 DI 없이 렌더)
- [ ] 접근성 라벨 부여 (§2.13)
- [ ] 파일 신규 생성 후 **`tuist generate` 실행** (AGENTS.md 규칙)
- [ ] Xcode `Cmd + B` 빌드 성공
- [ ] 커밋 메시지 형식: `[KAN-55] <subject>` (AGENTS.md 규칙)
- [ ] 커밋 단위 분리 권장:
  - C1: Service 스텁·프로토콜·DI 등록
  - C2: Feature-local 컴포넌트 (Components/ 하위)
  - C3: 루트 View·ViewModel·BottomSheet·Placeholder
  - C4: `ContentView` NavigationStack 배선 + Assembly

---

## 5. 백엔드 API 스펙 — **전부 TODO(BE-API)**

> BE 명세가 아직 준비되지 않음. 본 티켓은 **프론트 UI + 로컬 상태 + 서비스 스텁**까지만 구현한다. 아래 항목은 모두 `// TODO(BE-API):` 주석으로 `SpotService`·DTO 상단에 명시해 두고, BE 스펙이 확정되면 신규 티켓(KAN-XX)에서 교체.

확인 필요 항목:

- 엔드포인트 path / method (`POST /spots` 추정)
- 이미지 업로드 방식
  - (A) `multipart/form-data` 한 번에 모든 필드 + 이미지
  - (B) `POST /uploads` 으로 presigned URL 획득 → S3 직업로드 → `POST /spots`에 URL 전달
- 카테고리 enum 키 (`sunset` / `reflection` / 그 외?)
- 좌표 + 주소 payload 형식 (`Address` 구조 그대로 vs `place_id` 문자열?)
- `captured_at` 타임존/포맷 (ISO 8601 + TZ 권장)
- 응답 payload (`SpotId`만 vs 상세 엔티티 전체?)
- 실패 시 에러 코드 매핑

**스텁 구현 규칙** (§3.2):
- `registerSpot(draft:)`는 **네트워크 호출 없이** 1초 지연 후 `SpotId(rawValue: UUID().uuidString)` 반환.
- `NetworkManager`는 건드리지 않는다 (KAN-46에서 추가된 `requestJSON` 확장이 develop에 아직 merge 전일 수 있으므로 독립적으로 스텁만).

---

## 6. 작업 범위 밖 (Out of Scope)

- 주소 검색 화면 — 별도 티켓(예정). `장소 검색하기` 버튼은 no-op + `#if DEBUG` Mock 주입.
- 스팟 상세 화면 — 별도 티켓. 등록 성공 후 `SpotDetailPlaceholderView` 임시 표시.
- 실제 이미지 업로드 / 서버 API 연동 — BE 스펙 확정 후 별도 티켓.
- 사진 다중 선택, 카메라 촬영, 이미지 편집/크롭.
- 카테고리 다중 선택 / 추가 카테고리.
- 토스트 시스템 — `.alert`로 대체.
- Wheel picker의 픽셀 레벨 커스텀(시안 100% 일치) — MVP는 SwiftUI 기본 wheel, 추후 디자인 polish 티켓.
- 오프라인/임시저장 기능.
- 거리(`2.5km`) 실측 계산 — Mock 표시만.

---

## 7. 예상 디렉터리 스냅샷 (작업 후)

```
Pickflow/Sources/
├── App/
│   ├── AppContainer.swift            # 수정 (SpotService 등록)
│   ├── ContentView.swift             # 수정 (NavigationStack + 진입 링크)
│   └── PickflowApp.swift
├── Core/
│   └── Services/
│       ├── SpotService.swift         # NEW (스텁)
│       └── Protocols/
│           └── SpotServiceProtocol.swift  # NEW
└── Feature/
    ├── SpotRegistration/             # NEW
    │   ├── SpotRegistrationAssembly.swift
    │   ├── SpotRegistrationModels.swift
    │   ├── SpotRegistrationView.swift
    │   ├── SpotRegistrationViewModel.swift
    │   ├── SpotDetailPlaceholderView.swift
    │   └── Components/
    │       ├── CaptureDatePickerSheet.swift
    │       ├── CaptureDateTimeRow.swift
    │       ├── CaptureTimePickerSheet.swift
    │       ├── CountedTextEditor.swift
    │       ├── CountedTextField.swift
    │       ├── LabeledSection.swift
    │       ├── PhotoCategoryChipGroup.swift
    │       ├── SpotAddressCard.swift
    │       ├── SpotPhotoPickerCard.swift
    │       └── SpotSearchLocationButton.swift
    └── Profile/
```

---

## 8. 에이전트 응답 포맷

다음 순서로 응답한다:

1. **변경 요약** — 어떤 파일을 만들고 왜 그렇게 나눴는지 2–3문장.
2. **파일별 전체 코드** — 각 파일마다 절대 경로를 제목으로, 그 아래에 전체 소스를 ```swift 블록으로.
3. **기존 파일 diff** — `AppContainer.swift`, `ContentView.swift` 수정분.
4. **실행 명령** — `tuist generate`, 빌드 명령, 커밋 명령을 순서대로.
5. **후속 티켓 연결** — 주소 검색(별도), 스팟 상세(별도), 서버 연동(별도, §9), 카테고리 enum 확정(§9).
6. **🔔 유저에게 리소스 요청 (§9)** — 개발 마지막 단계에 반드시 포함.

---

## 9. 🔔 개발 종료 시 유저에게 요청할 리소스 (필수 단계)

에이전트는 코드 작성이 끝난 직후, 응답 마지막에 아래 항목 중 **누락/미확정 건을 체크리스트**로 제공한다. 임의 값 생성 금지.

### 9.1. BE API
- [ ] 스팟 등록 엔드포인트(path/method)
- [ ] 이미지 업로드 방식(multipart vs presigned URL)
- [ ] 요청/응답 스키마 (`spot_name`, `captured_at`의 타임존/ISO 형식, 좌표 필드 이름 등)
- [ ] 카테고리 enum 키 (`sunset`, `reflection` 이 맞는지)
- [ ] 에러 코드 매핑
- [ ] 거리(`2.5km`) 계산 방식: 서버가 주는 값인지 vs 현재 위치로 클라가 계산하는지

### 9.2. 디자인 자산
- [ ] 오렌지 포인트 컬러 HEX 확정 (`#FF6A2A` 가정치)
- [ ] 다크 배경 / 카드 배경 HEX 확정
- [ ] 카테고리 chip 선택 상태 시안 (보더 vs 배경 틴트)
- [ ] 사진 카드 placeholder 아이콘(현재 SF Symbol 대체)
- [ ] `장소 검색하기` 버튼 아이콘 에셋
- [ ] 노을/윤슬 아이콘 에셋 (현재 이모지 대체)
- [ ] Wheel picker 최종 스펙 (폰트/라인 하이라이트/간격)

### 9.3. 정책/플로우
- [ ] 등록 성공 후 이동 상세 화면의 실제 경로(티켓 번호)
- [ ] 실패/로딩 UX (현재 `.alert` + 버튼 스피너)
- [ ] 미래 날짜/시간 완전 차단이 맞는지(여행 계획 등 미래 스팟 케이스 가능성)
- [ ] 취소 시 경고 다이얼로그 필요 여부(입력값 버리기 방지)

### 9.4. 연동 티켓 예정
- 주소 검색 화면 — 별도 티켓(미지정)
- 스팟 상세 화면 — 별도 티켓(미지정)
- 서버 실연동 — BE 스펙 확정 후 신규 티켓

---

**끝. 위 명세 그대로 구현 시작. 마지막에 §9의 리소스 요청을 빼먹지 말 것.**
