# [KAN-82] 지도 클러스터링 — 논의 / 결정 / 후속 합의

본 PR(`feature/KAN-82`)에서 결정된 사항과 NMC SDK 통합 과정에서 학습한 내용, 후속 티켓으로 넘어가는 항목을 정리한다.

## 1. 본 PR에서 확정된 결정

| 영역 | 결정 | 근거 |
|---|---|---|
| 클러스터링 알고리즘 | **클라이언트 `NMCClusterer`** | 서버는 viewport 영역 spots만 필터링하여 반환. NMC SDK가 클러스터링 수행 |
| my spot 모델 | `MySpot` 별도 (Codable, Sendable, Identifiable) | 큐레이션 `ClusterableSpot`과 책임 분리 (스코프 §1, 정책 §2) |
| my spot 마커 | NMCClusterer 외부에서 `[NMFMarker]` 직접 관리 | 클러스터링에 참여하지 않음 — Coordinator가 보유 |
| Cluster Key | `MapSpotClusterKey: NMCClusteringKey`, `Int64 spotId` 보관 | leaf marker 탭 시 `info.key`로 spot id 추출 |
| Dictionary tag value | **`NSNull()`** 강제 | `NSNumber` 사용 시 NMC가 마커를 렌더링하지 않음 (디버그 확정, §5 참조) |
| Clusterer 재생성 | spots 변경 시에만 — selectedSpotId 변경에서 재생성 ❌ | cluster 위치 흔들림 방지 (§3 참조) |
| leaf marker selected 보더 | `leafMarkerRefs: [Int64: NMFMarker]` 보관, `iconImage`만 직접 교체 | clusterer 건드리지 않고 보더 토글 |
| 줌 임계 | `NMCBuilder.maxZoom = 15` | 줌 ≤ 15 클러스터 / 16+ leaf marker. 16에서 클러스터 탭 21점프 방지 |
| Debounce | NaverMapView `Coordinator.mapViewCameraIdle` 300ms | ViewModel은 즉시 fetch (Phase A 안티 패턴 회피) |
| 빈 공간 탭 | `NMFMapViewTouchDelegate.mapView(_:didTapMap:point:)` → `mapBackgroundTapped()` → selectedSpotId nil | 자동 선택 해제 |
| 마커 디자인 | `ClusterPinView` 주황 / `MyClusterPinView` 회색 그라데이션 + "MY" / `SpotMarkerView` 검정 그라데이션 + icPhoto | Figma 시안 매칭. `.strokeBorder` (inside-stroke)로 4pt 보더 |
| 시뮬 환경 | iPhone 17 Pro Max iOS 26.0 | 스냅샷 매트릭스 디바이스 고정 |
| `ClusteringExampleView` | **삭제** (2026-05-11) | KAN-82 NMC 통합 학습 통제군으로 활용 후 정리 |

## 2. 후속 합의 / 미해결

| ID | 항목 | 메모 |
|---|---|---|
| (c) | viewport 직렬화 포맷 | `bbox=lat1,lng1,...` vs 4 corners 분리 — BE-API 합의 시점. 현재는 4 corners |
| (f) | `ClusterableSpot` 메타 필드 | 테마/썸네일 등 — 서버 합의 시 protocol 시그니처 유지하며 필드만 추가 |
| (i) | NMC Builder 옵션 튜닝 | `screenDistance` 등 추가 조정 여지. 현재는 default |
| (j) | debounce 인터벌 | 300ms 적용. 사용자 피드백 따라 조정 |
| (k) | 클러스터 마커 선택 흐름 | NMC `NMCClusterMarkerInfo`가 자식 keys 비노출 → cluster의 selected 보더는 본 PR에선 SwiftUI 뷰 단에 디자인만 준비. 후속 티켓에서 cluster 탭 선택 정책 정의 필요 |
| (l) | spot 선택 시 버텀시트 | 본 PR은 `selectedSpotId` publish만. 상세 UI/네비게이션은 후속 |
| (m) | Figma 컴포넌트별 node-id 매핑 | §11 미입력 — 후속 디자인 합의 후 채움 |

## 3. NMC SDK 통합 학습 노트 (트러블슈팅 기록)

향후 NMC 통합 작업자가 같은 함정에 빠지지 않도록 본 PR에서 검증된 사실을 기록.

### 3.1 UIViewControllerRepresentable 필수

`UIViewRepresentable`로 `NMFNaverMapView` 직접 반환 형태에서는 `NMCBuilder.leafMarkerUpdater` / `clusterMarkerUpdater` 콜백이 호출되지 않는다. **`UIViewController` + `UIViewControllerRepresentable` 래핑이 필수**. ([KAN-51] `ClusteringExampleView` 패턴이 유일하게 동작했던 이유)

### 3.2 Dictionary tag value는 NSNull

```swift
clusterer.addAll([key: NSNumber(value: spotId)])  // ❌ 마커 렌더링 안 됨
clusterer.addAll([key: NSNull()])                  // ✅
```

원인: NMC SDK 내부 dedup/cluster bucket 처리가 `NSNumber` tag와 충돌. **tag는 NSNull 고정, spot id는 cluster key에 보관**.

### 3.3 Clusterer 재생성 vs Marker 갱신

| 시나리오 | 동작 |
|---|---|
| spots ids 변경 | clusterer 재생성 필요 (mapView nil → builder.build() → addAll → mapView 재설정) |
| spots ids 동일, selectedSpotId만 변경 | clusterer 재생성 ❌. leaf marker NMFMarker reference 보관해 `iconImage`만 직접 교체 |

재생성 시 cluster center가 미세하게 흔들리는 부작용 발생 (Swift `Dictionary` unordered 또는 NMC 내부 비결정성).

### 3.4 Swift 6 Strict Concurrency

- `NMFMapViewCameraDelegate`, `NMFMapViewTouchDelegate` 채택 시 **`@preconcurrency`** 필요
- `NMCDefaultLeafMarkerUpdater` 콜백에서 controller 접근 시 **`MainActor.assumeIsolated`**
- `NMFMarker`를 reference로 들고 다닐 때 **`extension NMFMarker: @unchecked @retroactive Sendable {}`** 필요 (main thread 격리 전제)

### 3.5 `info.key` 활용

`NMCLeafMarkerInfo`는 `tag` 외에 `key`(NMCClusteringKey) 노출. spot id는 cluster key에 보관해두고 `(info.key as? MapSpotClusterKey)?.spotId`로 추출. `NMCClusterMarkerInfo`는 자식 keys 비노출.

### 3.6 ImageRenderer

```swift
renderer.scale = max(UIScreen.main.scale, 3.0) * 1.5  // jagged 방지
```

SwiftUI Circle 보더는 **`.strokeBorder`** (inside-stroke). `.stroke`는 center-stroke라 frame 가장자리에서 lineWidth의 절반이 잘림.

## 4. 사전 broken 보정 (본 PR scope 외이지만 함께 처리)

KAN-51 머지 시점에 protocol에 추가됐지만 mock 갱신이 누락된 결함:

- `SpotServiceProtocol.registerSpot(draft:)` — `MockSpotService.registerSpot` 추가
- `LocationServiceProtocol.authorizationStatus()` — `MockLocationService.authorizationStatus()` 추가 + `CoreLocation` import

`PickflowTests` 모듈이 빌드되지 않아 본 PR의 ViewModel/Snapshot 테스트가 실행 불가능했기에 함께 보정. 별도 PR 분리 가능하지만 한 줄짜리 fix라 본 PR에 포함.

## 5. 빌드/검증 환경

| 항목 | 값 |
|---|---|
| 시뮬레이터 | iPhone 17 Pro Max iOS 26.0 |
| Swift | 6.0 / `SWIFT_STRICT_CONCURRENCY: complete` |
| Tuist | manifest `Project.swift` + `Tuist/Package.swift` |
| 신규 의존성 | `pointfreeco/swift-snapshot-testing` 1.19.2 (PickflowTests external) |
| Snapshot 매트릭스 | 20 케이스 (8 ClusterPin + 3 MyCluster + 4 SpotMarker + 1 a11y + 4 selected) GREEN |
| ViewModel 테스트 | 10 케이스 GREEN |
