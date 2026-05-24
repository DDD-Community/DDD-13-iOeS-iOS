# KAN-53 나의 보관함 — UI Test Cases

Phase B 산출물. Phase C 스냅샷 매트릭스의 단일 진실 소스.

| case id | 컴포넌트 | 상태/입력 조건 | 테마 | 언어 / DynamicType | Light/Dark | 디바이스 | 기대 시각 결과 | 스냅샷 파일명 |
|---|---|---|---|---|---|---|---|---|
| archive-root-signed-out-light | ArchiveView (전체화면) | state=.signedOut | — | ko_KR / .large | Light | iPhone 15 | 탭바 노출, 중앙에 카카오/애플 로그인 버튼과 "보관함 이용을 위해 로그인이 필요해요" 문구 | archive-root-signed-out-light.png |
| archive-root-signed-out-dark | ArchiveView (전체화면) | state=.signedOut | — | ko_KR / .large | Dark | iPhone 15 | Light와 동일 레이아웃, 다크 배경·버튼 색상 | archive-root-signed-out-dark.png |
| archive-root-loading-light | ArchiveView (전체화면) | state=.loading | — | ko_KR / .large | Light | iPhone 15 | 헤더 영역은 회색 placeholder, 그리드 영역은 ProgressView 또는 스켈레톤 | archive-root-loading-light.png |
| archive-root-loading-dark | ArchiveView (전체화면) | state=.loading | — | ko_KR / .large | Dark | iPhone 15 | Light와 동일 레이아웃, 다크 색상 | archive-root-loading-dark.png |
| archive-root-loaded-light | ArchiveView (전체화면) | state=.loaded(items: 8개, hasNext: false) | — | ko_KR / .large | Light | iPhone 15 | 헤더 이미지(첫 번째 스팟 썸네일), 탭바, Masonry 2열 그리드에 스팟 카드 8개 | archive-root-loaded-light.png |
| archive-root-loaded-dark | ArchiveView (전체화면) | state=.loaded(items: 8개, hasNext: false) | — | ko_KR / .large | Dark | iPhone 15 | Light와 동일 레이아웃, 다크 배경 | archive-root-loaded-dark.png |
| archive-root-empty-light | ArchiveView (전체화면) | state=.empty, selectedTab=.savedSpots | — | ko_KR / .large | Light | iPhone 15 | 탭바 노출, 중앙에 "저장된 스팟이 없어요" 문구 + "스팟 둘러보기" 버튼 | archive-root-empty-light.png |
| archive-root-empty-dark | ArchiveView (전체화면) | state=.empty, selectedTab=.savedSpots | — | ko_KR / .large | Dark | iPhone 15 | Light와 동일 레이아웃, 다크 배경 | archive-root-empty-dark.png |
| archive-root-failed-light | ArchiveView (전체화면) | state=.failed("네트워크 오류") | — | ko_KR / .large | Light | iPhone 15 | 탭바 노출, 중앙에 에러 메시지 텍스트 + 재시도 버튼 | archive-root-failed-light.png |
| archive-root-failed-dark | ArchiveView (전체화면) | state=.failed("네트워크 오류") | — | ko_KR / .large | Dark | iPhone 15 | Light와 동일 레이아웃, 다크 배경 | archive-root-failed-dark.png |
| archive-signed-out-content-light | ArchiveSignedOutContent | isLoginLoading=false | — | ko_KR / .large | Light | iPhone 15 | "보관함 이용을 위해 로그인이 필요해요" 타이틀, 카카오 버튼(노란 배경), 애플 버튼(검정 배경) 세로 배치 | archive-signed-out-content-light.png |
| archive-signed-out-content-dark | ArchiveSignedOutContent | isLoginLoading=false | — | ko_KR / .large | Dark | iPhone 15 | Light와 동일 레이아웃, 다크 배경 (MyProfileSignedOutContent 패턴 동일) | archive-signed-out-content-dark.png |
| archive-signed-out-content-accessibility-dark | ArchiveSignedOutContent | isLoginLoading=false | — | ko_KR / .accessibilityExtraLarge | Dark | iPhone 15 | 버튼 텍스트가 큰 폰트로 렌더링되어도 버튼 영역이 잘리지 않고 레이아웃 유지 | archive-signed-out-content-accessibility-dark.png |
| archive-signed-out-loading-kakao-dark | ArchiveSignedOutContent | isLoginLoading=true (카카오 로그인 중) | — | ko_KR / .large | Dark | iPhone 15 | 카카오 버튼에 ProgressView 스피너, 애플 버튼 dimmed 처리 | archive-signed-out-loading-kakao-dark.png |
| archive-signed-out-loading-apple-dark | ArchiveSignedOutContent | isLoginLoading=true (애플 로그인 중) | — | ko_KR / .large | Dark | iPhone 15 | 애플 버튼에 ProgressView 스피너, 카카오 버튼 dimmed 처리 | archive-signed-out-loading-apple-dark.png |
| archive-header-expanded-light | ArchiveHeaderView | 헤더 펼침 상태, thumbnailUrl=nil | — | ko_KR / .large | Light | iPhone 15 | 전체 높이 헤더, 중앙 "나의 보관함" 타이틀, ··· 버튼 우상단, 배경 회색 placeholder | archive-header-expanded-light.png |
| archive-header-expanded-dark | ArchiveHeaderView | 헤더 펼침 상태, thumbnailUrl=nil | — | ko_KR / .large | Dark | iPhone 15 | Light와 동일 레이아웃, 다크 배경 | archive-header-expanded-dark.png |
| archive-header-collapsed-dark | ArchiveHeaderView | 헤더 접힘 상태 (스크롤 후 sticky) | — | ko_KR / .large | Dark | iPhone 15 | 헤더 이미지 사라지고 탭바만 화면 상단에 sticky 고정 | archive-header-collapsed-dark.png |
| archive-tab-bar-saved-light | ArchiveTabBar | selectedTab=.savedSpots | — | ko_KR / .large | Light | iPhone 15 | "저장된 스팟" 탭 선택 indicator, "나만의 스팟" 비선택 | archive-tab-bar-saved-light.png |
| archive-tab-bar-saved-dark | ArchiveTabBar | selectedTab=.savedSpots | — | ko_KR / .large | Dark | iPhone 15 | Light와 동일 레이아웃, 다크 배경 | archive-tab-bar-saved-dark.png |
| archive-tab-bar-myspot-light | ArchiveTabBar | selectedTab=.mySpots | — | ko_KR / .large | Light | iPhone 15 | "나만의 스팟" 탭 선택 indicator, "저장된 스팟" 비선택 | archive-tab-bar-myspot-light.png |
| archive-tab-bar-myspot-dark | ArchiveTabBar | selectedTab=.mySpots | — | ko_KR / .large | Dark | iPhone 15 | Light와 동일 레이아웃, 다크 배경 | archive-tab-bar-myspot-dark.png |
| archive-myspot-placeholder-light | ArchiveMySpotPlaceholder | selectedTab=.mySpots | — | ko_KR / .large | Light | iPhone 15 | "나만의 스팟" 선택 시 "준비 중입니다" 등 out-of-scope placeholder 문구만 표시 | archive-myspot-placeholder-light.png |
| archive-myspot-placeholder-dark | ArchiveMySpotPlaceholder | selectedTab=.mySpots | — | ko_KR / .large | Dark | iPhone 15 | Light와 동일 레이아웃, 다크 배경 | archive-myspot-placeholder-dark.png |
| archive-empty-view-light | ArchiveEmptyView | — | — | ko_KR / .large | Light | iPhone 15 | 빈 상태 아이콘/일러스트, "저장된 스팟이 없어요" 라벨, "스팟 둘러보기" 버튼 | archive-empty-view-light.png |
| archive-empty-view-dark | ArchiveEmptyView | — | — | ko_KR / .large | Dark | iPhone 15 | Light와 동일 레이아웃, 다크 배경 | archive-empty-view-dark.png |
| archive-loaded-grid-light | ArchiveLoadedGrid (MasonryTwoColumn) | items: 8개, thumbnailUrl=nil | — | ko_KR / .large | Light | iPhone 15 | 2열 Masonry 그리드, 각 셀에 회색 placeholder 이미지 + 스팟명 + 거리 | archive-loaded-grid-light.png |
| archive-loaded-grid-dark | ArchiveLoadedGrid (MasonryTwoColumn) | items: 8개, thumbnailUrl=nil | — | ko_KR / .large | Dark | iPhone 15 | Light와 동일 레이아웃, 다크 배경 | archive-loaded-grid-dark.png |
| archive-loaded-grid-thumbnail-nil-dark | ArchiveLoadedGrid (MasonryTwoColumn) | items: 4개, thumbnailUrl nil/non-nil 혼합 | — | ko_KR / .large | Dark | iPhone 15 | nil 셀은 회색 placeholder, non-nil 셀은 이미지 로드(AsyncImage placeholder) | archive-loaded-grid-thumbnail-nil-dark.png |
| archive-loaded-grid-accessibility-dark | ArchiveLoadedGrid (MasonryTwoColumn) | items: 4개, thumbnailUrl=nil | — | ko_KR / .accessibilityExtraLarge | Dark | iPhone 15 | 카드 내 텍스트(스팟명, 거리)가 큰 폰트로도 카드 레이아웃이 깨지지 않음 | archive-loaded-grid-accessibility-dark.png |
