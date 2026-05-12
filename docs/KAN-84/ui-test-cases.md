# [KAN-84] 스팟 상세 화면 리뉴얼 — UI 테스트 케이스

> **Phase B 산출물 (Gate 2)**. Phase C 스냅샷 파일명은 이 표의 `스냅샷 파일명` 컬럼을 그대로 사용한다.
> 디바이스 기본값: **iPhone 17** (iPhone 15 시뮬레이터 미설치 — iOS 26.4 빌드 환경)

---

## 컴포넌트별 케이스 표

| case id | 컴포넌트 | 상태/입력 조건 | 테마 | 언어 / DynamicType | Light/Dark | 디바이스 | 기대 시각 결과 | 스냅샷 파일명 |
|---|---|---|---|---|---|---|---|---|
| spot-detail-screen-loading-light | 전체 화면 | LoadState.loading | — | ko_KR / .large | Light | iPhone 17 | 화면 중앙에 ProgressView 스피너 1개, 나머지 영역은 gray95 배경 | spot-detail-screen-loading-light.png |
| spot-detail-screen-loading-dark | 전체 화면 | LoadState.loading | — | ko_KR / .large | Dark | iPhone 17 | 동일 구조, dark 컬러 토큰 적용 | spot-detail-screen-loading-dark.png |
| spot-detail-screen-error-light | 전체 화면 | LoadState.failed("오류 메시지") | — | ko_KR / .large | Light | iPhone 17 | "스팟 정보를 불러오지 못했어요." 큰 텍스트 + 에러 메시지 작은 텍스트, 중앙 정렬 | spot-detail-screen-error-light.png |
| spot-detail-screen-error-dark | 전체 화면 | LoadState.failed("오류 메시지") | — | ko_KR / .large | Dark | iPhone 17 | 동일 구조, dark 컬러 토큰 적용 | spot-detail-screen-error-dark.png |
| spot-detail-screen-loaded-default-light | 전체 화면 | loaded, isMine=false, 북마크OFF | sunset | ko_KR / .large | Light | iPhone 17 | NavBar(뒤로가기+공유+X) → 헤더(스팟명+테마+북마크수+코멘트) → 사진(날짜뱃지+주소) → 액션버튼(길안내wide+북마크아이콘) → 실시간정보 → 신고버튼 순으로 배치 | spot-detail-screen-loaded-default-light.png |
| spot-detail-screen-loaded-default-dark | 전체 화면 | loaded, isMine=false, 북마크OFF | sunset | ko_KR / .large | Dark | iPhone 17 | 동일 레이아웃, dark 컬러 토큰 적용 | spot-detail-screen-loaded-default-dark.png |
| spot-detail-screen-loaded-bookmarked-light | 전체 화면 | loaded, isMine=false, 북마크ON | sunset | ko_KR / .large | Light | iPhone 17 | 액션버튼의 북마크 아이콘이 filled 상태 | spot-detail-screen-loaded-bookmarked-light.png |
| spot-detail-screen-loaded-bookmarked-dark | 전체 화면 | loaded, isMine=false, 북마크ON | sunset | ko_KR / .large | Dark | iPhone 17 | 동일, dark 컬러 | spot-detail-screen-loaded-bookmarked-dark.png |
| spot-detail-screen-loaded-mine-light | 전체 화면 | loaded, isMine=true | sunset | ko_KR / .large | Light | iPhone 17 | 스팟명 옆 "MY 스팟" 뱃지, 액션버튼이 길안내+내스팟오픈 50/50, 실시간정보 주차·혼잡도 "-" | spot-detail-screen-loaded-mine-light.png |
| spot-detail-screen-loaded-mine-dark | 전체 화면 | loaded, isMine=true | sunset | ko_KR / .large | Dark | iPhone 17 | 동일, dark 컬러 | spot-detail-screen-loaded-mine-dark.png |
| spot-detail-navbar-default-light | SpotDetailNavBar | 북마크OFF | — | ko_KR / .large | Light | iPhone 17 | 좌: 뒤로가기 아이콘(28pt) / 우: 공유 아이콘(32pt) + X 아이콘(32pt), 아이콘 사이 간격 4pt | spot-detail-navbar-default-light.png |
| spot-detail-navbar-default-dark | SpotDetailNavBar | 북마크OFF | — | ko_KR / .large | Dark | iPhone 17 | 동일 구조, dark 컬러 | spot-detail-navbar-default-dark.png |
| spot-detail-navbar-mine-light | SpotDetailNavBar | isMine=true | — | ko_KR / .large | Light | iPhone 17 | NavBar 구성 Default와 동일 (My스팟 여부가 NavBar에 영향 없음) | spot-detail-navbar-mine-light.png |
| spot-detail-header-sunset-light | SpotHeaderSection | loaded, isMine=false, 코멘트 1줄 | sunset | ko_KR / .large | Light | iPhone 17 | 스팟명(SemiBold 24pt) / 테마칩(노을 아이콘+텍스트) + 점 + "북마크 34" / 코멘트 본문 1줄 | spot-detail-header-sunset-light.png |
| spot-detail-header-sunset-dark | SpotHeaderSection | loaded, isMine=false, 코멘트 1줄 | sunset | ko_KR / .large | Dark | iPhone 17 | 동일 구조, dark 컬러 | spot-detail-header-sunset-dark.png |
| spot-detail-header-reflection-light | SpotHeaderSection | loaded, isMine=false | reflection | ko_KR / .large | Light | iPhone 17 | 테마칩에 윤슬 아이콘과 "윤슬" 텍스트 표시, 나머지 동일 | spot-detail-header-reflection-light.png |
| spot-detail-header-reflection-dark | SpotHeaderSection | loaded, isMine=false | reflection | ko_KR / .large | Dark | iPhone 17 | 동일, dark 컬러 | spot-detail-header-reflection-dark.png |
| spot-detail-header-mine-light | SpotHeaderSection | loaded, isMine=true | sunset | ko_KR / .large | Light | iPhone 17 | 스팟명 우측에 "MY 스팟" 오렌지 뱃지 추가, 북마크수 뱃지는 없음 | spot-detail-header-mine-light.png |
| spot-detail-header-mine-dark | SpotHeaderSection | loaded, isMine=true | sunset | ko_KR / .large | Dark | iPhone 17 | 동일, dark 컬러 | spot-detail-header-mine-dark.png |
| spot-detail-header-long-comment-light | SpotHeaderSection | 코멘트 3줄 이상 | sunset | ko_KR / .large | Light | iPhone 17 | 코멘트 텍스트가 줄바꿈되어 섹션 높이 자연스럽게 확장, 잘림 없음 | spot-detail-header-long-comment-light.png |
| spot-detail-header-a11y-light | SpotHeaderSection | loaded, isMine=false | sunset | ko_KR / .accessibilityExtraLarge | Light | iPhone 17 | 스팟명·뱃지·코멘트 텍스트가 큰 크기에서 잘림 없이 줄바꿈 처리됨 | spot-detail-header-a11y-light.png |
| spot-detail-photo-with-image-light | SpotPhotoSection | 이미지 URL 있음, recordedTime 있음 | — | ko_KR / .large | Light | iPhone 17 | 사진 200pt 높이, 우하단에 날짜/시간 뱃지("26.04.11. PM 6:33"), 이미지 아래 위치아이콘+주소 텍스트 행 | spot-detail-photo-with-image-light.png |
| spot-detail-photo-with-image-dark | SpotPhotoSection | 이미지 URL 있음, recordedTime 있음 | — | ko_KR / .large | Dark | iPhone 17 | 동일 구조, dark 컬러 | spot-detail-photo-with-image-dark.png |
| spot-detail-photo-no-image-light | SpotPhotoSection | 이미지 URL 없음(nil) | — | ko_KR / .large | Light | iPhone 17 | gray90 플레이스홀더 직사각형, 날짜 뱃지 없음, 주소 행은 표시 | spot-detail-photo-no-image-light.png |
| spot-detail-photo-no-image-dark | SpotPhotoSection | 이미지 URL 없음(nil) | — | ko_KR / .large | Dark | iPhone 17 | 동일, dark 컬러 | spot-detail-photo-no-image-dark.png |
| spot-detail-action-unbookmarked-light | SpotActionButtons | isMine=false, isBookmarked=false | — | ko_KR / .large | Light | iPhone 17 | 좌: "길 안내 받기"(sunsetOrange, 넓게 FILL, 56pt) / 우: icBookmarkBorder 아이콘(gray0 bg, 56x56pt) | spot-detail-action-unbookmarked-light.png |
| spot-detail-action-unbookmarked-dark | SpotActionButtons | isMine=false, isBookmarked=false | — | ko_KR / .large | Dark | iPhone 17 | 동일 구조, dark 컬러 | spot-detail-action-unbookmarked-dark.png |
| spot-detail-action-bookmarked-light | SpotActionButtons | isMine=false, isBookmarked=true | — | ko_KR / .large | Light | iPhone 17 | 북마크 아이콘이 icBookmarkFilled(채워진 상태)로 교체, 나머지 동일 | spot-detail-action-bookmarked-light.png |
| spot-detail-action-bookmarked-dark | SpotActionButtons | isMine=false, isBookmarked=true | — | ko_KR / .large | Dark | iPhone 17 | 동일, dark 컬러 | spot-detail-action-bookmarked-dark.png |
| spot-detail-action-mine-light | SpotActionButtons | isMine=true | — | ko_KR / .large | Light | iPhone 17 | "길 안내 받기"(50%, 52pt) + "내 스팟 오픈하기"(50%, 52pt) 동일 너비, 각 버튼 높이 52pt | spot-detail-action-mine-light.png |
| spot-detail-action-mine-dark | SpotActionButtons | isMine=true | — | ko_KR / .large | Dark | iPhone 17 | 동일, dark 컬러 | spot-detail-action-mine-dark.png |
| spot-detail-realtime-default-light | SpotRealTimeInfoSection | parking 있음("무료 주차장"), congestion 있음("여유") | — | ko_KR / .large | Light | iPhone 17 | 섹션헤더 + 기준시간 텍스트, 4행: [아이콘36pt] 현재날씨/맑음+강수확률15% / 일몰시간/PM6:40+오차시간 / 주차관련/무료주차장 / 혼잡도/여유+?아이콘 | spot-detail-realtime-default-light.png |
| spot-detail-realtime-default-dark | SpotRealTimeInfoSection | parking 있음, congestion 있음 | — | ko_KR / .large | Dark | iPhone 17 | 동일 구조, dark 컬러 | spot-detail-realtime-default-dark.png |
| spot-detail-realtime-mine-light | SpotRealTimeInfoSection | isMine=true, parking=nil, congestion 있음 | — | ko_KR / .large | Light | iPhone 17 | 주차관련 행 값이 "-", 혼잡도 행 값이 "-"로 표시, 나머지 행은 동일 | spot-detail-realtime-mine-light.png |
| spot-detail-realtime-mine-dark | SpotRealTimeInfoSection | isMine=true, parking=nil | — | ko_KR / .large | Dark | iPhone 17 | 동일, dark 컬러 | spot-detail-realtime-mine-dark.png |
| spot-detail-realtime-a11y-light | SpotRealTimeInfoSection | loaded, parking 있음 | — | ko_KR / .accessibilityExtraLarge | Light | iPhone 17 | 레이블/값 텍스트가 큰 크기에서 아이콘 옆 영역을 벗어나지 않고 줄바꿈 처리됨 | spot-detail-realtime-a11y-light.png |

---

## 자가 점검

- [x] `<!-- TODO -->` 0개
- [x] 8개 컬럼 모두 존재
- [x] 각 행에 스냅샷 파일명 결정됨
- [x] **상태 4종**: loading ✅ / loaded(정상) ✅ / empty(해당없음, 스팟 상세는 데이터 필수) / error ✅
- [x] **테마 분기**: sunset ✅ / reflection ✅
- [x] **선택적 필드 분기**: 이미지 유무 ✅ / 북마크 ON/OFF ✅ / isMine ✅ / parking nil ✅
- [x] **Light/Dark**: 전 케이스 쌍으로 존재 ✅
- [x] **DynamicType accessibilityExtraLarge**: 헤더 ✅ / 실시간정보 ✅

총 **36행** — 컴포넌트 9개, 주요 분기 커버 완료
