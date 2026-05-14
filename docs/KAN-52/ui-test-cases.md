# [KAN-52] 스팟 리스트 UI 테스트 케이스

> Phase B 산출물. 행마다 결정된 `스냅샷 파일명`이 Phase C에서 swift-snapshot-testing 케이스 식별자로 그대로 쓰인다.
> 운용 가이드: `docs/phases/phase-b-ui-cases.md`

## 매트릭스

| case id | 컴포넌트 | 상태/입력 조건 | 테마 | 언어 / DynamicType | Light/Dark | 디바이스 | 기대 시각 결과 | 스냅샷 파일명 |
|---|---|---|---|---|---|---|---|---|
| spot-list-loaded-mixed-light | SpotListView | `.loaded(items: 6, hasNext: true)`. 노을 3 / 윤슬 3, 모두 거리 있음, 북마크 OFF | mixed | ko_KR / .large | Light | iPhone 15 | 2열 Pinterest 그리드, 짝수 인덱스는 좌 컬럼, 홀수는 우 컬럼. 셀 좌상단 mood overlay 표시. 하단 무한 스크롤 트리거 영역 노출 | spot-list-loaded-mixed-light.png |
| spot-list-loaded-mixed-dark | SpotListView | 동일 | mixed | ko_KR / .large | Dark | iPhone 15 | Light와 동일 레이아웃, 다크 팔레트 적용 | spot-list-loaded-mixed-dark.png |
| spot-list-loaded-single-light | SpotListView | `.loaded(items: 1, hasNext: false)`. 노을 1개 | sunset | ko_KR / .large | Light | iPhone 15 | 좌 컬럼에 1개 셀만 존재, 우 컬럼은 비어 있음. 무한 스크롤 sentinel 없음 | spot-list-loaded-single-light.png |
| spot-list-loaded-single-dark | SpotListView | 동일 | sunset | ko_KR / .large | Dark | iPhone 15 | 동일 레이아웃 다크 | spot-list-loaded-single-dark.png |
| spot-list-loading-light | SpotListView | `.loading` | — | ko_KR / .large | Light | iPhone 15 | 2열 스켈레톤 카드 6개 (썸네일/이름/거리 자리). 필터 바는 보임 | spot-list-loading-light.png |
| spot-list-loading-dark | SpotListView | `.loading` | — | ko_KR / .large | Dark | iPhone 15 | 동일 스켈레톤 다크 | spot-list-loading-dark.png |
| spot-list-empty-light | SpotListView | `.empty` | — | ko_KR / .large | Light | iPhone 15 | 중앙 일러스트 + "조건에 맞는 스팟이 없어요" 안내. 필터 바는 유지 | spot-list-empty-light.png |
| spot-list-empty-dark | SpotListView | `.empty` | — | ko_KR / .large | Dark | iPhone 15 | 동일 다크 | spot-list-empty-dark.png |
| spot-list-empty-a11y-light | SpotListView | `.empty` | — | ko_KR / .accessibilityExtraLarge | Light | iPhone 15 | 안내 텍스트가 2~3줄로 줄바꿈, 일러스트는 유지. 잘림 없음 | spot-list-empty-a11y-light.png |
| spot-list-failed-light | SpotListView | `.failed("네트워크 오류")` | — | ko_KR / .large | Light | iPhone 15 | 중앙 에러 일러스트 + 메시지 + "다시 시도" 버튼 | spot-list-failed-light.png |
| spot-list-failed-dark | SpotListView | `.failed("네트워크 오류")` | — | ko_KR / .large | Dark | iPhone 15 | 동일 다크 | spot-list-failed-dark.png |
| spot-list-unauthorized-light | SpotListView | `.locationUnauthorized` | — | ko_KR / .large | Light | iPhone 15 | 위치 권한 안내 일러스트 + "설정으로 이동" 버튼. 필터/그리드 미표시 | spot-list-unauthorized-light.png |
| spot-list-unauthorized-dark | SpotListView | `.locationUnauthorized` | — | ko_KR / .large | Dark | iPhone 15 | 동일 다크 | spot-list-unauthorized-dark.png |
| spot-list-unauthorized-a11y-light | SpotListView | `.locationUnauthorized` | — | ko_KR / .accessibilityExtraLarge | Light | iPhone 15 | 안내 텍스트 줄바꿈, 버튼 영역 확장. 잘림 없음 | spot-list-unauthorized-a11y-light.png |
| spot-list-filterbar-default-light | FilterSortBar | selectedTheme=nil, sort=.nearest | — | ko_KR / .large | Light | iPhone 15 | 노을·윤슬 capsule 둘 다 비활성 보더, 우측 "가까운 순" 셀렉터 | spot-list-filterbar-default-light.png |
| spot-list-filterbar-default-dark | FilterSortBar | 동일 | — | ko_KR / .large | Dark | iPhone 15 | 동일 다크 | spot-list-filterbar-default-dark.png |
| spot-list-filterbar-sunset-selected-light | FilterSortBar | selectedTheme=.sunset | sunset | ko_KR / .large | Light | iPhone 15 | 노을 capsule에 sunsetOrange 보더, 윤슬은 비활성 | spot-list-filterbar-sunset-selected-light.png |
| spot-list-filterbar-sunset-selected-dark | FilterSortBar | 동일 | sunset | ko_KR / .large | Dark | iPhone 15 | 동일 다크 | spot-list-filterbar-sunset-selected-dark.png |
| spot-list-filterbar-reflection-selected-light | FilterSortBar | selectedTheme=.reflection | reflection | ko_KR / .large | Light | iPhone 15 | 윤슬 capsule만 활성 보더 | spot-list-filterbar-reflection-selected-light.png |
| spot-list-filterbar-reflection-selected-dark | FilterSortBar | 동일 | reflection | ko_KR / .large | Dark | iPhone 15 | 동일 다크 | spot-list-filterbar-reflection-selected-dark.png |
| spot-list-filterbar-sort-bookmark-light | FilterSortBar | sort=.bookmark | — | ko_KR / .large | Light | iPhone 15 | 정렬 셀렉터 라벨이 "북마크 순"으로 변경, 필터 capsule은 비활성 | spot-list-filterbar-sort-bookmark-light.png |
| spot-list-cell-sunset-bookmark-off-light | SpotListCell | mood=sunset, isBookmarked=false, distance=1.2km, bookmarkCount=12, 썸네일 있음 | sunset | ko_KR / .large | Light | iPhone 15 | 썸네일 + 좌상단 sunset overlay, 이름 1줄, "노을" 라벨, "📍 1.2km · ♡ 12" (icBookmarkBorder) | spot-list-cell-sunset-bookmark-off-light.png |
| spot-list-cell-sunset-bookmark-off-dark | SpotListCell | 동일 | sunset | ko_KR / .large | Dark | iPhone 15 | 동일 다크 | spot-list-cell-sunset-bookmark-off-dark.png |
| spot-list-cell-sunset-bookmark-on-light | SpotListCell | mood=sunset, isBookmarked=true, distance=1.2km, bookmarkCount=13 | sunset | ko_KR / .large | Light | iPhone 15 | 북마크 아이콘이 icBookmarkFilled, 카운트 +1 반영된 13 | spot-list-cell-sunset-bookmark-on-light.png |
| spot-list-cell-reflection-bookmark-off-light | SpotListCell | mood=reflection, isBookmarked=false, distance=0.4km | reflection | ko_KR / .large | Light | iPhone 15 | 좌상단 sparklingRipple overlay, "윤슬" 라벨, 거리 0.4km | spot-list-cell-reflection-bookmark-off-light.png |
| spot-list-cell-reflection-bookmark-off-dark | SpotListCell | 동일 | reflection | ko_KR / .large | Dark | iPhone 15 | 동일 다크 | spot-list-cell-reflection-bookmark-off-dark.png |
| spot-list-cell-distance-nil-light | SpotListCell | distance=nil (위경도 미전달), 나머지 정상 | sunset | ko_KR / .large | Light | iPhone 15 | 거리 라벨 영역 자체가 숨겨지고 "♡ 12"만 표시 | spot-list-cell-distance-nil-light.png |
| spot-list-cell-thumbnail-nil-light | SpotListCell | thumbnailUrl=nil | sunset | ko_KR / .large | Light | iPhone 15 | 썸네일 자리에 gray95 placeholder + mood overlay 유지 | spot-list-cell-thumbnail-nil-light.png |
| spot-list-cell-long-name-truncate-light | SpotListCell | name="아주아주 긴 한강 노을 스팟 이름 테스트 케이스" | sunset | ko_KR / .large | Light | iPhone 15 | 이름 1줄에서 말줄임표(…)로 truncate, 무드 라벨/거리/카운트는 정상 | spot-list-cell-long-name-truncate-light.png |
| spot-list-cell-a11y-light | SpotListCell | mood=sunset, 정상 | sunset | ko_KR / .accessibilityExtraLarge | Light | iPhone 15 | 이름은 2~3줄 줄바꿈, 거리/카운트가 다음 줄로 wrap, 셀 높이 확장. 잘림 없음 | spot-list-cell-a11y-light.png |

## 최소 커버리지 자가 점검

- [x] **상태 4종**: loading / loaded / empty / failed + 추가 `locationUnauthorized`
- [x] **테마 분기**: sunset / reflection 각각 셀·필터바에 분리 행
- [x] **선택 필드 분기**: distance nil, thumbnail nil, 긴 이름 truncate
- [x] **Light/Dark**: 정상 시나리오 모두 한 쌍씩 (총 ~30행)
- [x] **DynamicType `.accessibilityExtraLarge`**: 셀 / 빈 상태 / 권한 안내 3행

## 스냅샷 환경 가정

- `SnapshotEnvironment` 활용 (KAN-51 선례), `record` 기본 false
- `precision: 0.99` 권장 (앤티앨리어싱 차이 흡수)
- 디바이스 기본 iPhone 15, 필요 시 `viewImageConfig: .iPhone15` 명시
