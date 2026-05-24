# KAN-107 핑퐁 검증 트러블 로그

> 시뮬레이터(iPhone 17 Pro Max, iOS 26.0) + ConsoleNetworkLogger 핑퐁 결과 모음.
> 검증 흐름은 진행하면서 발견된 이슈만 누적 기록한다. 수정/PR은 검증 완료 후 일괄 처리.

---

## Step 4-1: 지도 진입 — `GET /v1/spots/viewport`

**기대:** 진입 시 1회 호출, 4개 코너 좌표 포함.
**실측:** 4개 코너는 포함되나 **호출 4회 + 모두 400 응답**.

### ✅ 1-A 픽스 완료 (`MapClusteringViewModel.swift:17-39`)
- `MapClusteringViewModel.viewportChanged(_:)` 에 `debounceTask` + `Task.sleep(300ms)` 디바운스 적용.
- 짧은 시간 내 연속 발사된 호출은 마지막 1건만 실제 fetch 까지 살아남고, 이전 호출은 `Task.cancel()` 로 폐기됨.
- `debounceMillis` init 파라미터로 외부에서 주입 가능 (테스트에선 0ms).
- 단위 테스트 추가: `test_viewportChanged_짧은시간내연속호출_마지막호출만fetch된다`.

### 이슈 1-A. (원본) viewport 중복 호출 (×4)
- 동일 좌표 4회 연속 발사됨.
- 추정 원인: 지도 카메라 idle 콜백, `onAppear`, 위치 권한 콜백 등이 초기 진입 시 중복 트리거 → debounce 미적용.
- 확인 필요 위치: `ClusteringService.fetchViewport()` 호출 진입점 (지도 화면 ViewModel/Reducer 의 `onAppear` + 카메라 변화 옵저버).
- 액션 후보:
  - 카메라 변화 옵저버에 debounce(예: 300ms) 적용.
  - 초기 진입은 `onAppear` 1회로 통일하고 카메라 idle 콜백 첫 발사를 무시.

### ✅ 1-B 픽스 완료 (`SpotEndpoint.swift:27-43`)
- viewport 파라미터 8개 모두 `(v * 1_000_000).rounded() / 1_000_000` 로 6자리 클램프.
- 재검증: `topLeftLat=37.583994` 로 전송, **200 OK** 받고 spotId 3·16 반환됨.

### 이슈 1-B. (원본) 좌표 정밀도 위반 → 400 Bad Request
- 서버: `위도/경도는 소수점 6자리까지 허용합니다.` (code C001)
- 클라이언트 전송 예시:
  - `topLeftLat=37.58399355264859` (14자리)
  - `topLeftLng=127.011295757521` (12자리)
- 결과: viewport 가 **한 번도 성공하지 못함** → 지도 마커 빈 상태일 가능성.
- 액션 후보:
  - viewport endpoint 파라미터 빌드 지점에서 `String(format: "%.6f", value)` 로 반올림 후 전송.
  - 또는 endpoint Encodable 모델에서 `Double` 대신 6자리로 클램프한 값 사용.
- 확인 위치: `Pickflow/Sources/Core/Services/Endpoints/` 의 viewport endpoint 파라미터 정의.

---

## 진행 메모

- 검증은 **이슈를 고치지 않고** 4-2 ~ 4-10 시나리오를 계속 핑퐁한다.
- 각 단계에서 새 이슈가 나오면 아래 섹션으로 추가.
- 검증 완료 후 우선순위 매겨 일괄 수정 / PR 분할.

---

## Step 4-2: 카메라 팬·줌 — _대기 중_
## Step 4-3: 무드 SUNSET capsule — ⚠️ 스펙 이탈

**기대:** viewport 호출에 `&theme=SUNSET` 부착.
**실측:**
- `GET /v1/spots/viewport?...` × 2회 — theme 파라미터 **없음**, 여전히 400 (1-B와 동일).
- `GET /v1/spots?latitude=...&longitude=...&page=0&sort=DISTANCE&theme=SUNSET` × 1회 — 200 OK, SUNSET 스팟 5건 반환.

### ✅ 3-A 픽스 완료 (`HomeMapView.swift:76`)
- 원인: `clustering.themeChanged(mood?.rawValue)` 가 한국어 라벨 `"노을"`/`"윤슬"` 을 전달.
- `ClusteringService.fetchViewport` 내부의 `SpotTheme.init?(apiCode:)` 는 `SUNSET/YUNSEUL/SS/YS` 만 매핑 → `nil` → endpoint theme 빠짐.
- 픽스: `mood?.rawValue` → `mood?.spotTheme.apiCode` ("SUNSET"/"YUNSEUL").

### 이슈 3-A. (원본) theme 가 viewport 가 아니라 list 엔드포인트로 라우팅됨
- 명세는 "지도 마커 필터링을 위한 theme 부착(viewport)"인데, 실제 구현은 list 엔드포인트(`/v1/spots`)에 theme 를 붙임.
- 결과: **지도 모드에서 무드 변경 시 마커가 필터링되지 않음** (viewport 는 theme 무시).
- 확인 위치: 무드 capsule 탭 액션이 호출하는 Service. `ClusteringService.fetchViewport` 가 아닌 `SpotListService.fetchSpots` 로 라우팅되는지 점검.
- 액션 후보:
  - 무드 탭 액션을 viewport 재호출 + `theme` 쿼리 추가하도록 변경.
  - 만약 List 모드도 동시에 갱신해야 한다면 둘 다 발사.

### ✅ 4-3/4-4 재검증 PASS
- SUNSET: viewport?...&theme=SUNSET → 200, spotId 3 단일.
- YUNSEUL: viewport?...&theme=YUNSEUL → 200, spotId 16 단일.

## Step 4-4: 무드 YUNSEUL capsule — ⚠️ (원본) 동일 패턴 (3-A 와 동일)

- viewport ×2 (theme 없음, 400) + `GET /v1/spots?...&theme=YUNSEUL` ×1 (200, 5건 반환).
- 이슈는 3-A 와 동일하므로 동일 픽스로 처리 예정.

### ✅ 4-5 재검증 PASS (네트워크)
- 5-A 픽스 후 `GET /v1/spots?...&sort=DISTANCE&theme=YUNSEUL` 정상 디코딩, 리스트 렌더링 시작됨.
- 페이지네이션도 작동: page=0 → 1 → 2 까지 자동 호출됨 (무한스크롤 또는 prefetch).

### ✅ 5-B 픽스 완료 (`SpotListCell.swift:18-72`, `MasonryTwoColumn.swift:22-39`)

**최종 해결책**: GeometryReader 로 cell width 를 lock 하고 height = width × aspect 명시 강제.
```swift
private var thumbnailBox: some View {
    let aspect: CGFloat = item.spotId.isMultiple(of: 2) ? 1.2 : 0.9
    return GeometryReader { proxy in
        let w = proxy.size.width
        let h = w * aspect
        ZStack(alignment: .top) {
            thumbnail(width: w, height: h)
            // badges overlay
        }
        .frame(width: w, height: h)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .aspectRatio(1.0 / aspect, contentMode: .fit)
}
```
+ `MasonryTwoColumn` 두 컬럼에 `.frame(maxWidth: .infinity)` 명시로 균등 너비 분배.

**실패한 시도들**:
1. 1차 (서브에이전트): 외부 ZStack 에 `.aspectRatio(.fit) + .clipShape()` + AsyncImage 에 `.frame(maxWidth/maxHeight: .infinity).clipped()` — **효과 없음**. AsyncImage 의 intrinsic size 가 여전히 cell width 를 흔듦.
2. 2차: HStack 두 컬럼에 `.frame(maxWidth: .infinity)` 추가 — width 분배는 좋아졌지만 cell 내부 width 가 여전히 image intrinsic 에 휘둘림 → 더 심한 침범 발생.
3. 3차 (최종): GeometryReader 안에서 proxy.size.width 를 받아 cell 내부에 명시 `.frame(width: w, height: h)` 강제 → image cascade 차단.

### 이슈 5-B. (원본) Masonry/그리드 셀 레이아웃 깨짐
- 증상: 셀 boundary 를 넘어 옆 셀로 콘텐츠가 흘러나옴 (큰 이미지가 작은 셀 위로 침범, 텍스트 라벨도 옆 칸으로 넘어감).
- 네트워크/디코딩 단은 정상이므로 **순수 UI 레이아웃 버그**.

### 근본 원인
SwiftUI 의 `AsyncImage` + `.scaledToFill()` 조합은 image success phase 에서 intrinsic size 를 layout 으로 다시 흘려보낸다. 이게 부모 `ZStack` 의 사이즈 결정에 cascade 영향을 주는데, 부모(`LazyVStack` 안의 cell) 가 자체 width 를 self-referential 하게 가지려 하면 layout cycle 이 무너진다.

- `.frame(maxWidth: .infinity)` + `.aspectRatio(.fit)` 만으로는 부족: `.fit` 은 부모로부터 frame 을 받아 비율로 줄이는 모드. LazyVStack 부모가 자식 크기를 따라가는 구조에서는 fit 의 reference 가 없음.
- `.clipped()` 는 drawing bounds 만 자르고 layout bounds 는 그대로. 옆 컬럼으로 시각적 침범은 막지만 width 자체는 계속 흔들림.
- **결정적**: image intrinsic size 가 cell width 를 결정하는 cascade 가 한 곳에서라도 깨지면 row alignment 가 무너진다.

### 왜 GeometryReader 가 해결책인가
- GR 은 부모로부터 사이즈를 받아 `proxy.size.width` 로 노출. 이 값으로 명시 `.frame(width:height:)` 를 박으면 그 안의 view(AsyncImage 포함) 는 더 이상 자기 intrinsic size 로 cascade 를 흔들 수 없다.
- 외부 `.aspectRatio(1/aspect, .fit)` 는 GR 자체의 frame 을 부모(LazyVStack) 가 비율로 제한하도록 ideal size 힌트 제공.
- 결과: width 는 부모 컬럼이 결정한 값으로 고정, height 만 image aspect 따라 변동 — **진짜 masonry 동작**.

### GeometryReader 성능 트레이드오프
- **현 구조에서는 OK**: `LazyVStack` 이 화면에 보이는 cell 만 instantiate → GR 인스턴스도 visible 만 생성. iPhone 한 화면에 마운트되는 GR 수는 ~10개 미만.
- iOS 16+ 부터 SwiftUI layout engine 이 GR 의 layout pass 를 더 효율적으로 처리. 과거(iOS 15 이하) 처럼 빈번한 invalidation cascade 부담은 작음.
- 다만 **부모-1회 GR + columnWidth prop 주입** 패턴이 더 깔끔: `MasonryTwoColumn` 자체에 GR 1회 두고 `columnWidth: CGFloat` 를 cell 에 전달. cell 내부 GR 제거 가능 → cell 마다 GR 비용 0.
- iOS 17+ 라면 `containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: 12, alignment: .leading)` 로 GR 없이 자동 분배 가능. 더 깔끔하지만 deployment target 확인 필요.

### 후속 리팩터 후보 (별도 티켓)
1. **부모-1회 GR**: `MasonryTwoColumn` 에 GR 한 번만 두고 `(proxy.size.width - spacing) / 2` 를 cell 에 `columnWidth` prop 으로 전달. cell 내부 GR 제거.
2. **iOS 17+ `containerRelativeFrame`**: deployment target 이 17+ 라면 GR 자체를 제거.
3. **`SpotListItem` 에 명시 aspect 필드**: 현재는 `spotId.isMultiple(of: 2) ? 1.2 : 0.9` 로 가짜 vary. BE 가 이미지 width:height 메타를 같이 내려주면 셀별 실제 비율로 표시 가능.

### Lesson
- SwiftUI 에서 셀 width 를 잠그고 싶으면 `.frame(maxWidth: .infinity) + .aspectRatio(.fit)` 만으로는 부족. **명시 width 가 어딘가에 박혀야** AsyncImage / 동적 컨텐츠의 cascade 를 막을 수 있다.
- GeometryReader 가 가장 견고한 도구. 단점은 cell 마다 인스턴스 비용 — LazyVStack 안에서는 visible 만 instantiate 되므로 실용적 수준에서 문제 없음.
- Masonry 의 기본 원칙: **width 고정, height 만 컨텐츠로 변동**. 이 invariant 가 깨지면 컬럼 alignment 부터 무너진다.

## Step 4-5: 하단 List 토글 — (원본) ❌ 네트워크 200 / UI "스팟 불러오기 실패"

**기대:** `GET /v1/spots?page=0&sort=DISTANCE&latitude=...&longitude=...` 1회 + 리스트 렌더.
**실측:** 호출 자체는 200 (`/api/v1/spots?...&sort=DISTANCE&theme=YUNSEUL`), 응답 body 정상이지만 화면은 에러 상태.

### 이슈 5-A. `SpotTheme` 디코딩 실패 — 서버 축약 코드 미지원
- 서버 응답: `"theme":"SS"` (sunset), `"YS"` (윤슬) — 축약형.
- 클라 `SpotTheme.init?(apiCode:)`: 오직 `"SUNSET"`, `"YUNSEUL"` 만 허용 → `nil` → `init(from:)` 가 `DecodingError.dataCorruptedError` throw.
- `SpotListItem.theme: SpotTheme` (옵셔널 아님)이라 페이지 전체 디코딩이 실패하고 ViewModel 이 에러 상태로 들어감.
- 동일 모델: `Spot.theme`, `SpotPreviewResponse.theme` — Step 4-7, 4-8 도 같은 이유로 실패할 가능성 높음.

### 액션 후보
- A안 (권장): `SpotTheme.init?(apiCode:)` 에 축약 코드(`"SS"`, `"YS"`)도 매핑 추가.
  ```swift
  case "SUNSET", "SS": self = .sunset
  case "YUNSEUL", "YS": self = .reflection
  ```
- B안: 서버에 풀네임으로 통일 요청 (백엔드 협의 필요, 시간 소요).
- 확인 위치: `Pickflow/Sources/Core/Services/Models/Spot.swift` line 67-73.

### 관찰: 4-5 자체의 호출은 List 엔드포인트 1회만 발사됨 ✅
- viewport 추가 호출 없음. theme 가 이미 켜져있던 상태(YUNSEUL)라서 sort=DISTANCE&theme=YUNSEUL 로 1회만 발사. 호출 횟수 측면은 OK.

### ✅ 4-6 재검증 PASS
- sort 토글 후 page=0 부터 재시작, page=1 까지 자동 호출 확인.

## Step 4-6: 정렬 RECOMMENDED — (원본) ✅ 네트워크 OK

- `GET /v1/spots?...&sort=RECOMMENDED&theme=YUNSEUL` × 1회 → 200, 추천 순서로 5건 반환.
- sort 파라미터만 변경되고 나머지 쿼리(latitude/longitude/page/theme) 동일 — 명세 일치.
- UI 는 5-A(SpotTheme 디코딩) 때문에 여전히 에러 상태 추정.

### 🆕 이슈 9-A. `SpotDetail` 옵셔널 필드 누락 → 디코딩 실패
- 서버 응답에 `recordedDate/recordedTime/weatherSky/precipitation/precipitationProbability/congestionLevel/sunsetTime/astronomyDate/weatherUpdatedAt/congestionUpdatedAt` 가 모두 `null` 로 옴.
- 클라 `SpotDetail` 정의는 위 필드 모두 non-optional → 첫 null 만나면 throw → "스팟 정보를 불러오지 못했어요".
- ✅ 픽스: 위 10개 필드를 옵셔널로, `weatherDisplayName` computed 도 옵셔널화, `SpotRealTimeInfoSection` 콜사이트(sunsetTime/precipitationProbability/congestionLevel) `??` fallback 처리.
- 영향 확인 필요: `SpotDetailDebugMocks.swift` 는 그대로 두면 됨 (옵셔널이라도 값 들어감).

## Step 4-8: 시트 large/fullCover 드래그 — ⚠️ Detail 호출 중복

**기대:** preview→large 전환 시 detail ×1.
**실측:** medium→large→fullCover 드래그하는 동안 `GET /v1/spots/16` 가 **3번 추가 호출** (4-7 합산 총 4회).

### ✅ 8-A 픽스 완료 (`SpotDetailViewModel.swift:loadDetailIfNeeded`)
- `loadDetailIfNeeded()` 가 `detailState == .loaded` 또는 `.loading` 일 때 early-return.
- `detailLoadTask` 가드로 in-flight 중복 발사도 차단.
- 결과: spotId 별 detail 응답이 ViewModel 인스턴스 전 생애주기에서 1회만 호출됨 (성공 시).
- 단위 테스트 추가: `test_updateDetent_large_이미loaded면_detail재호출하지않는다`.

### 이슈 8-A. (원본) detent 변경마다 detail 재호출, 캐싱 없음
- detent change 콜백이 매번 `fetchSpotDetail` 발사. 동일 응답을 반복 수신.
- 액션 후보:
  - 한 번 fetch 된 spotId 의 detail 은 ViewModel state 에 캐시하고 detent 콜백에선 재발사 안 함.
  - 또는 7-A 와 묶어서 "large 진입 시점에만 1회" 로 통일.
- 우선순위: 동작은 됨 → 별도 PR.

## Step 4-7: 마커 탭 — ⚠️ preview + detail 동시 호출 (스펙 이탈)

**기대:** preview ×1 (sheet medium 시점).
**실측:**
- `GET /v1/spots/16/preview?latitude=...&longitude=...` × 1 (200, theme="YUNSEUL")
- `GET /v1/spots/16` × 1 (200, detail 풀바디)

### ✅ 7-A 픽스 완료 (`SpotDetailViewModel.swift:onAppear`)
- `onAppear()` 는 이제 `previewState` 만 로드, `detailState = .idle` 유지.
- detail 은 `updateDetent(.large)` / `promoteToFullCover()` 콜에서 `loadDetailIfNeeded()` 로 lazy fetch.
- 결과: 마커 탭 (sheet medium) 시점엔 preview 1회만 발사. large 드래그 진입 시 detail 1회 발사 (8-A 캐싱과 결합).
- 단위 테스트 추가: `test_onAppear_detail은즉시fetch되지않고preview만로드된다`, `test_updateDetent_large_detail이fetch된다`.

### 이슈 7-A. (원본) detail 호출이 preview 단계에서 함께 발사
- 명세는 4-8 (시트 large 드래그) 단계에서 detail 호출. 현재는 마커 탭 즉시 둘 다 발사 — 트래픽 낭비, large 미진입 시에도 detail 비용 발생.
- 액션 후보: bottom sheet detent 가 large 로 전환될 때만 `SpotService.fetchSpotDetail` 호출하도록 ViewModel 수정. 확인 위치 후보: 마커 탭 액션 처리 ViewModel (HomeMapView/HomeMapViewModel/SpotDetailViewModel) 또는 bottom sheet detent change 핸들러.
- 우선순위: 동작은 작동 → KAN-107 핵심 검증 후 별도 PR.

### ✅ 부가 확인
- preview/detail 응답의 `theme` 는 풀네임 `"YUNSEUL"` 로 옴 (`/spots` 리스트만 `SS/YS` 축약). 5-A 픽스 덕에 모두 디코딩 PASS.

## Step 4-9 / 4-10: 북마크 ON / OFF — ⏸ 보류 (인증 필요)

- 북마크 토글은 로그인된 상태에서만 호출 가능 → 다음 세션으로 미룸.
- 재개 시: 로그인 후 detail 화면에서 북마크 ON 탭 → `POST /v1/spots/{id}/bookmarks` 확인 → OFF 탭 → `DELETE /v1/spots/{id}/bookmarks` 확인.

---

## Step 4-7 ~ 4-10: (원본) 검증 불가 ⛔

지도에 마커가 표시되지 않아 진입 불가. 근본 원인은 **이슈 1-B (viewport 좌표 정밀도 위반으로 400)**.
이슈 1-B 가 픽스되어 viewport 가 200을 받기 시작하면 4-7 (마커 탭 preview), 4-8 (시트 detail), 4-9/4-10 (북마크) 모두 재시도 가능.

### 검증 재개 선결 조건
1. **1-B 픽스**: viewport 파라미터 빌드 지점에서 좌표 6자리 반올림.
2. **5-A 픽스**: `SpotTheme.init?(apiCode:)` 에 `"SS"`, `"YS"` 매핑 추가 — 안 그러면 preview/detail 응답도 디코딩 실패.

위 두 픽스 후 다시 시뮬 띄워 4-7부터 핑퐁 재개.

---

## 회고: 실기기에서만 재현된 좌표 정밀도 위반 (List/Preview)

### ✅ 픽스 완료 (`SpotListEndpoint.swift:14-33`, `SpotPreviewEndpoint.swift:12-19`)
- `/v1/spots` 의 `latitude`/`longitude` 파라미터에 6자리 클램프 적용
  (`r: (Double) -> Double = { (($0 * 1_000_000).rounded()) / 1_000_000 }`).
- `/v1/spots/{id}/preview` 도 동일 클램프 적용.
- 적용 후 실기기에서도 `GET /v1/spots?...&page=0&sort=DISTANCE` 200 OK 확인.

### 증상
- **시뮬에서는 통과, 실기기에서만 400** 발생.
- 시뮬 로그: `latitude=37.392142&longitude=126.920587` (6자리) → 200 OK.
- 실기기 로그: `latitude=37.39447341274778&longitude=126.9137738120952` (14자리) → 400, `C001 위도/경도는 소수점 6자리까지`.

### 왜 시뮬은 통과했는가
- iOS Simulator 의 `CLLocationManager` 가 반환하는 `coordinate.latitude/longitude` 는 Apple 가 미리 정의한 시뮬 위치(예: `37.392142, 126.920587`) 의 **이미 6자리로 떨어진 상수**.
- 따라서 클라이언트가 6자리 클램프를 누락해도 시뮬 환경에서는 쿼리가 자동으로 6자리로만 직렬화 → 서버 검증 통과.
- 실기기는 실제 GPS 측정값(14자리 Double full precision)을 그대로 흘려보냄 → 400.

### 1-B 와의 차이
- 1-B (viewport): 좌표가 **카메라 bounds 계산 결과**라 시뮬에서도 매번 14자리. **시뮬에서도 즉시 재현됨** → 초기에 발견·픽스.
- 이번 List/Preview: 좌표가 **`locationService.currentLocation()`** 결과를 그대로 흘려보냄. 시뮬은 상수 위치라 우연히 6자리 → 회피. **실기기에서만 노출**.

### Lesson
- 좌표를 외부 API 에 보내는 모든 Endpoint 는 출처가 무엇이든 6자리 클램프 일관 적용.
- 시뮬 위치 기반 검증은 **6자리 우연 통과** 케이스를 놓칠 수 있음. 좌표 직렬화는 단위 테스트(실수 값 → 6자리 String) 로 별도 가드 권장.
- 또는 `Coordinate` / shared helper 에 `clampedToSixDecimals()` 같은 명시적 변환을 두고, Endpoint 빌드 지점에서 강제하는 게 안전.
