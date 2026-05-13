# [KAN-82] 지도 클러스터링 — UI Test Cases (Phase B 산출물)

> 작성 가이드: [docs/phases/phase-b-ui-cases.md](../phases/phase-b-ui-cases.md). 본 표가 Phase C swift-snapshot-testing 매트릭스의 **단일 진실 소스**.
>
> 본 티켓 스코프: 클러스터링 **핀 컴포넌트** 시각화 ([implementation-prompt §1](map-clustering-implementation-prompt.md)). 화면 전체 loading/failed 상태 시각화는 본 티켓 범위 밖이라 매트릭스에서 제외.
>
> 핀은 SwiftUI 뷰(`ClusterPinView` / `MyClusterPinView` / `SpotMarkerView`)로 작성하고 `NaverMapView`가 `ImageRenderer`로 `UIImage` 변환하여 `NMFOverlayImage`에 주입. 매트릭스 단위는 SwiftUI 뷰.

---

## 매트릭스

| case id | 컴포넌트 | 상태/입력 조건 | 테마 | 언어 / DynamicType | Light/Dark | 디바이스 | 기대 시각 결과 | 스냅샷 파일명 |
|---|---|---|---|---|---|---|---|---|
| `cluster-pin-count2-light` | ClusterPinView | count=2 (소) | — | ko_KR / .large | Light | iPhone 15 | 직경 44pt 원형, `sunsetOrange` 솔리드 배경, 중앙에 "2" 흰색 `body(.small(.bold))` | `cluster-pin-count2-light.png` |
| `cluster-pin-count2-dark` | ClusterPinView | count=2 (소) | — | ko_KR / .large | Dark | iPhone 15 | 직경 44pt 원형, `sunsetOrange` 솔리드(다크에서도 동일 토큰), "2" 흰색 텍스트 | `cluster-pin-count2-dark.png` |
| `cluster-pin-count12-light` | ClusterPinView | count=12 (중) | — | ko_KR / .large | Light | iPhone 15 | 직경 54pt 원형, `sunsetOrange` 솔리드, "12" 흰색 텍스트 중앙 | `cluster-pin-count12-light.png` |
| `cluster-pin-count12-dark` | ClusterPinView | count=12 (중) | — | ko_KR / .large | Dark | iPhone 15 | 직경 54pt 원형, `sunsetOrange` 솔리드, "12" 흰색 텍스트 중앙 | `cluster-pin-count12-dark.png` |
| `cluster-pin-count75-light` | ClusterPinView | count=75 (대) | — | ko_KR / .large | Light | iPhone 15 | 직경 64pt 원형, `sunsetOrange` 솔리드, "75" 흰색 텍스트 중앙 | `cluster-pin-count75-light.png` |
| `cluster-pin-count75-dark` | ClusterPinView | count=75 (대) | — | ko_KR / .large | Dark | iPhone 15 | 직경 64pt 원형, `sunsetOrange` 솔리드, "75" 흰색 텍스트 중앙 | `cluster-pin-count75-dark.png` |
| `cluster-pin-count150-light` | ClusterPinView | count=150 (특대) | — | ko_KR / .large | Light | iPhone 15 | 직경 74pt 원형, `sunsetOrange` 솔리드, "150" 흰색 텍스트 중앙 | `cluster-pin-count150-light.png` |
| `cluster-pin-count150-dark` | ClusterPinView | count=150 (특대) | — | ko_KR / .large | Dark | iPhone 15 | 직경 74pt 원형, `sunsetOrange` 솔리드, "150" 흰색 텍스트 중앙 | `cluster-pin-count150-dark.png` |
| `cluster-pin-count12-a11y-light` | ClusterPinView | count=12, DynamicType 확대 | — | ko_KR / .accessibilityExtraLarge | Light | iPhone 15 | 원 직경은 고정, 텍스트만 `body(.small(.bold))` 토큰의 a11y 스케일링 적용. 텍스트가 원 안에서 잘리지 않음을 확인 | `cluster-pin-count12-a11y-light.png` |
| `my-cluster-pin-light` | MyClusterPinView | 단일 my spot 마커 | — | ko_KR / .large | Light | iPhone 17 Pro Max | 직경 56pt 원형, 회색 LinearGradient(top white 0.45 → bottom white 0.85), 흰색 1pt 외곽 stroke + 그림자, 중앙에 `Maps/icPhoto` 아이콘 위 + "MY" 흰색 `body(.small(.bold))` 텍스트 아래 | `my-cluster-pin-light.png` |
| `my-cluster-pin-dark` | MyClusterPinView | 단일 my spot 마커 | — | ko_KR / .large | Dark | iPhone 17 Pro Max | 직경 56pt, 동일 회색 그라데이션, `icPhoto` + "MY" 흰색 | `my-cluster-pin-dark.png` |
| `my-cluster-pin-a11y-dark` | MyClusterPinView | DynamicType 확대 | — | ko_KR / .accessibilityExtraLarge | Dark | iPhone 17 Pro Max | 텍스트 a11y 스케일링 적용, 아이콘+MY 텍스트 레이아웃이 원 안에서 잘리지 않음 | `my-cluster-pin-a11y-dark.png` |
| `spot-marker-default-light` | SpotMarkerView | isSelected=false | — | ko_KR / .large | Light | iPhone 15 | 직경 44pt 원형, 검정 LinearGradient(top alpha 0 → bottom alpha 0.7), 중앙에 `Maps/icPhoto`. border 없음 | `spot-marker-default-light.png` |
| `spot-marker-default-dark` | SpotMarkerView | isSelected=false | — | ko_KR / .large | Dark | iPhone 15 | 직경 44pt, 동일 그라데이션, `icPhoto` 중앙, border 없음 | `spot-marker-default-dark.png` |
| `spot-marker-selected-light` | SpotMarkerView | isSelected=true | — | ko_KR / .large | Light | iPhone 15 | 직경 44pt, 동일 그라데이션, `icPhoto` 중앙, **외곽 `sunsetOrange` 4pt 보더**가 추가됨 | `spot-marker-selected-light.png` |
| `spot-marker-selected-dark` | SpotMarkerView | isSelected=true | — | ko_KR / .large | Dark | iPhone 17 Pro Max | 직경 44pt, 동일 그라데이션, `icPhoto` 중앙, **외곽 `sunsetOrange` 4pt 보더 (strokeBorder, inside-stroke)** | `spot-marker-selected-dark.png` |
| `cluster-pin-count12-selected-light` | ClusterPinView | count=12, isSelected=true | — | ko_KR / .large | Light | iPhone 17 Pro Max | 직경 54pt 주황 원 + "12" 흰색 텍스트 + **외곽 `sunsetOrange` 4pt 보더 (strokeBorder)** | `cluster-pin-count12-selected-light.png` |
| `cluster-pin-count12-selected-dark` | ClusterPinView | count=12, isSelected=true | — | ko_KR / .large | Dark | iPhone 17 Pro Max | 동일 + 외곽 4pt 보더 | `cluster-pin-count12-selected-dark.png` |
| `my-cluster-pin-selected-light` | MyClusterPinView | isSelected=true | — | ko_KR / .large | Light | iPhone 17 Pro Max | 회색 그라데이션 단일 마커 + `icPhoto` + "MY" + **외곽 `sunsetOrange` 4pt 보더 (strokeBorder)** | `my-cluster-pin-selected-light.png` |
| `my-cluster-pin-selected-dark` | MyClusterPinView | isSelected=true | — | ko_KR / .large | Dark | iPhone 17 Pro Max | 동일 + 외곽 4pt 보더 | `my-cluster-pin-selected-dark.png` |

---

## 사이즈 분기 근거

`ClusterPinView`의 직경은 NaverMapView의 기존 `ClusterMarkerUpdater.clusterSize(for:)` 분기 그대로 사용:

| count 범위 | 직경 |
|---|---|
| `..<10` | 44pt |
| `..<50` | 54pt |
| `..<100` | 64pt |
| `100+` | 74pt |

→ 매트릭스의 4개 카운트(2 / 12 / 75 / 150)가 4개 사이즈 구간을 모두 커버.

`MyClusterPinView`는 **단일 사이즈 56pt 고정** — KAN-82 §1 스코프상 my spot은 클러스터링에 참여하지 않고 항상 단일 마커로 표시되므로 count 분기 자체가 없음. 디자인은 사용자 제공 시안(왕십리·잠원의 회색 그라데이션 MY 마커) 매칭.

---

## 자가 점검 (Phase B 종료 전)

- [x] 표에 `<!-- TODO -->` 가 0개
- [x] 모든 행에 스냅샷 파일명이 결정되어 있음 (`<case-id>.png`)
- [x] 8개 컬럼 모두 채워짐 (case id / 컴포넌트 / 상태 / 테마 / 언어·DynamicType / Light·Dark / 디바이스 / 기대 시각 결과 / 스냅샷 파일명)
- [x] **상태 분기**: 핀 컴포넌트엔 loading/empty/error 시각 분기 없음 — 입력값(count, isSelected) 분기로 대체. 화면 전체 상태 시각화는 본 티켓 범위 밖
- [x] **테마 분기**: 본 티켓의 클러스터링은 큐레이션 단일 데이터 — `theme` API 파라미터는 받지만 핀 시각엔 영향 없음 → `—` 표기
- [x] **선택적 필드 분기**: ClusterPinView count 4구간 (2/12/75/150) + SpotMarkerView isSelected (false/true) 커버. MyClusterPinView는 단일 디자인이라 분기 없음
- [x] **Light/Dark**: 모든 시나리오에서 한 쌍씩 (총 16행 = 8 ClusterPin + 3 MyCluster + 4 SpotMarker + 1 a11y light)
- [x] **DynamicType `.accessibilityExtraLarge`**: 텍스트가 들어가는 ClusterPinView·MyClusterPinView 각 1행씩
- [x] §1 스코프와 일치 (범위 밖 케이스 없음)
- [x] 리뷰어가 표만 읽고 스냅샷을 머릿속에 그릴 수 있음 (직경·색·아이콘 위치·텍스트가 모두 명시됨)

---

## 후속 합의 필요 (Phase C 진입 전 또는 Phase C 시각 검증 시)

- ~~(1) MyClusterPinView 사이즈 분기~~ ✅ 2026-05-11 확정 — **단일 56pt** (count 분기 없음)
- ~~(2) MyClusterPinView 텍스트~~ ✅ 2026-05-11 확정 — **"MY" 라벨** (개수가 아님, 클러스터링 미참여)
- (3) 그라데이션 — 회색 단계 (white 0.45 → 0.85) 적용. 정확한 stop은 시각 매칭으로 결정됨
- (4) `body(.small(.bold))` 토큰의 정확한 size/leading — Figma dev mode와 매칭

후속 Figma 합의 후 매트릭스 갱신 가능.
