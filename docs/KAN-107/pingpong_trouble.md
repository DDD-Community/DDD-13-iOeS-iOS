# KAN-107 핑퐁 검증 트러블 로그

> 시뮬레이터(iPhone 17 Pro Max, iOS 26.0) + ConsoleNetworkLogger 핑퐁 결과 모음.
> 검증 흐름은 진행하면서 발견된 이슈만 누적 기록한다. 수정/PR은 검증 완료 후 일괄 처리.

---

## Step 4-1: 지도 진입 — `GET /v1/spots/viewport`

**기대:** 진입 시 1회 호출, 4개 코너 좌표 포함.
**실측:** 4개 코너는 포함되나 **호출 4회 + 모두 400 응답**.

### 이슈 1-A. viewport 중복 호출 (×4)
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

### 🆕 이슈 5-B. Masonry/그리드 셀 레이아웃 깨짐
- 증상: 셀 boundary 를 넘어 옆 셀로 콘텐츠가 흘러나옴 (큰 이미지가 작은 셀 위로 침범, 텍스트 라벨도 옆 칸으로 넘어감).
- 네트워크/디코딩 단은 정상이므로 **순수 UI 레이아웃 버그**.
- 확인 위치 후보: `SpotListView` (Pickflow/Sources/Feature/Map/... 또는 별도 List feature 디렉터리). Masonry/StaggeredGrid 셀 사이즈 계산, `.clipped()`, aspect ratio 픽스.
- 우선순위: 네트워크 검증과 독립이므로 KAN-107 핑퐁 완료 후 별도 PR.

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

### 이슈 8-A. detent 변경마다 detail 재호출, 캐싱 없음
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

### 이슈 7-A. detail 호출이 preview 단계에서 함께 발사
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
