# KAN-127 구현 체크리스트

지도 클러스터 핀 사이즈 구분 · GPS 현재 위치 핀 축소 · 바텀시트 북마크 0 표시 작업에 대한 검증 체크리스트.

## 1. 클러스터 핀 M/L 사이즈 구분

- [x] `ClusterPinView.diameter(forCount:)`를 2단계로 변경 — **2~15개 → M(60×60)**, **16개 이상 → L(100×100)** (기존 4단계 44/54/64/74 제거)
  - 파일: `Pickflow/Sources/Feature/Map/Clustering/ClusterPinView.swift:25`
- [x] 마커 렌더 사이즈에 자동 반영 (단일 진실원) — `ClusteringMarkerImage.cluster`, `MapClusterMarkerUpdater.updateClusterMarker`
  - 파일: `Pickflow/Sources/Feature/Map/NaverMapView.swift`
- [x] 스냅샷으로 사이즈 검증: count2/12 → 180px(=60×3, M), count75/150 → 300px(=100×3, L)

## 2. GPS 현재 위치 오버레이 18×18

- [x] `updateUserLocation(_:)`에서 `iconWidth`/`iconHeight` 22 → **18**
  - 파일: `Pickflow/Sources/Feature/Map/NaverMapView.swift`
- [x] `userLocationDotImage` 렌더 사이즈 22×22 → **18×18**, 흰 테두리 비율 유지 위해 inset 3 → 2.5, 주석 갱신
- [ ] (수동) 실기/시뮬에서 주황색 현재 위치 점이 18pt로 표시되는지 육안 확인 — *라이브 지도 필요*

## 3. 바텀시트 북마크 0 표시

- [x] `themeAndBookmarkRow`에서 `if bookmarkCount > 0` 가드 제거 → **0도 "북마크 0"으로 표시**
  - 파일: `Pickflow/Sources/Feature/SpotDetail/SpotDetailSheetContentView.swift:88`
- [x] `!isMySpot` 조건으로 변경 — MY 스팟은 북마크 수 미표시 유지 (`SpotHeaderSection`과 일관성)
- [x] 스냅샷 렌더로 "노을 · 북마크 0" 표시 확인

## 4. 테스트 / 스냅샷

- [x] 신규 스냅샷 케이스 추가: `test_sheetContent_zeroBookmark_dark` (비-MY스팟 + bookmarkCount 0)
  - 파일: `PickflowTests/SpotDetailBottomSheetSnapshotTests.swift`
- [x] 클러스터 핀 스냅샷 11종 재기록 (count2/12/75/150 light·dark, a11y, selected)
- [x] 재검증 컴페어 통과 (6 tests, 0 failures)
- [x] (선행 결함 수정) 모델 `isBookmarked` 누락으로 빌드 불가했던 테스트 픽스처 3건 보정
  - `PickflowTests/Helpers/SpotDetailTestDoubles.swift`, `Helpers/SpotListTestDoubles.swift`, `ArchiveSnapshotTests.swift`

## 5. 빌드 검증

- [x] 앱 + 테스트 타깃 컴파일 성공 (`BUILD SUCCEEDED` / `TEST BUILD SUCCEEDED`)
  - 대상: iPhone 16 시뮬레이터, iOS 26.0
- [x] 시뮬레이터 설치/실행 확인 (온보딩 · 로그인 화면 정상 렌더)

## 6. 시뮬레이터 라이브 수동 검증 (지도 = 실제 백엔드 의존)

> 로그인 화면에서 **"비회원으로 시작하기"** 탭 → 지도 진입 후 확인

- [ ] 클러스터 핀이 2~15개일 때 M(60), 16개 이상일 때 L(100)로 구분되어 보이는지
- [ ] 마커 썸네일(동시 작업 `MarkerImageLoader`)이 핀에 사진으로 렌더되는지
- [ ] GPS 현재 위치 점이 18×18로 표시되는지
- [ ] 스팟 탭 → 바텀시트에서 북마크 0인 스팟이 "북마크 0"으로 노출되는지 (데이터에 0건 스팟 필요)

> 참고: 해당 viewport에 백엔드 스팟 데이터가 없으면 지도가 비어 보일 수 있음 (코드 이슈 아님).
