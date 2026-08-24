# [PV-40] 유저 스팟 공개 시스템 — UI Test Cases

> Phase B 산출물. Phase C 스냅샷 매트릭스의 단일 진실 소스.
>
> 대상은 스팟 상세에 **신규로 추가되는 컴포넌트 단위 스냅샷**이다.
> 화면 전체(`SpotDetailSnapshotTests`)는 이미 상태 4종을 다루고 있으므로 본 표에서 중복 정의하지 않는다.
> 시각 스펙의 출처는 `docs/PV-40/screens-detail.md` 「정밀 스펙」이며, 색·치수는 그 표를 따른다.
>
> 스냅샷 파일명은 레포 관례(`test_<메서드명>.1.png`)를 따른다 — swift-snapshot-testing 이 테스트 메서드명으로 파일을 만든다.
> **레퍼런스 PNG 는 아직 기록되지 않았다** — 이 환경에서는 시뮬레이터가 호스트 경로에 쓰지 못한다. Xcode 에서 `SpotPublicationSnapshotTests` 를 한 번 실행해 48장을 기록해야 한다.
>
> 재신청 폼(`Add-Filled-01`, `Add-ExitConfirm`)은 이번 범위 밖이다 — 재신청이 등록 API인지 수정 API인지 미확정이라 컴포넌트 구조가 정해지지 않았다.

## 컴포넌트 단위 케이스

| case id | 컴포넌트 | 상태/입력 조건 | 테마 | 언어 / DynamicType | Light/Dark | 디바이스 | 기대 시각 결과 | 스냅샷 파일명 |
|---|---|---|---|---|---|---|---|---|
| spot-status-badge-myspot-light | SpotStatusBadge | `.mySpot` | — | ko_KR / .large | Light | 390pt 고정 | 높이 25, radius 4, padding 4/8. 테두리 `#FA6133` 1px, 배경 없음, 라벨 "MY 스팟" 13 w600 `#FA6133` | test_spot_status_badge_myspot_light.1.png |
| spot-status-badge-myspot-dark | SpotStatusBadge | `.mySpot` | — | ko_KR / .large | Dark | 390pt 고정 | Light과 동일 (다크 전용 팔레트라 colorScheme 비의존) | test_spot_status_badge_myspot_dark.1.png |
| spot-status-badge-review-light | SpotStatusBadge | `.underReview` | — | ko_KR / .large | Light | 390pt 고정 | 테두리 없음. 배경 `#CDD1D5` 15% 불투명, 라벨 "검수 중" 13 w600 `#CDD1D5` | test_spot_status_badge_review_light.1.png |
| spot-status-badge-review-dark | SpotStatusBadge | `.underReview` | — | ko_KR / .large | Dark | 390pt 고정 | Light과 동일 | test_spot_status_badge_review_dark.1.png |
| spot-status-badge-rejected-light | SpotStatusBadge | `.rejected` | — | ko_KR / .large | Light | 390pt 고정 | 테두리 `#CDD1D5` 1px, 배경 없음, 라벨 "오픈 반려" 13 w600 `#CDD1D5` | test_spot_status_badge_rejected_light.1.png |
| spot-status-badge-rejected-dark | SpotStatusBadge | `.rejected` | — | ko_KR / .large | Dark | 390pt 고정 | Light과 동일 | test_spot_status_badge_rejected_dark.1.png |
| spot-detail-header-draft-light | SpotPublicationHeader | status = .draft, isMySpot, likeCount 미노출 | 윤슬 | ko_KR / .large | Light | 390pt 고정 | 1행: 타이틀 24 w600 `#F4F4F1` + "MY 스팟" 뱃지(gap 8). 2행: "윤슬" 15 w400 `#B1B8BE` 단독, 추천 카운트 없음 | test_spot_detail_header_draft_light.1.png |
| spot-detail-header-draft-dark | SpotPublicationHeader | 위와 동일 | 윤슬 | ko_KR / .large | Dark | 390pt 고정 | Light과 동일 | test_spot_detail_header_draft_dark.1.png |
| spot-detail-header-review-light | SpotPublicationHeader | status = .pending | 윤슬 | ko_KR / .large | Light | 390pt 고정 | 뱃지가 "검수 중"(회색 surface)로 바뀌고 나머지는 draft와 동일 | test_spot_detail_header_review_light.1.png |
| spot-detail-header-review-dark | SpotPublicationHeader | 위와 동일 | 윤슬 | ko_KR / .large | Dark | 390pt 고정 | Light과 동일 | test_spot_detail_header_review_dark.1.png |
| spot-detail-header-rejected-light | SpotPublicationHeader | status = .rejected | 윤슬 | ko_KR / .large | Light | 390pt 고정 | 뱃지 "오픈 반려"(회색 라인). 서브타이틀은 "윤슬"만 — 반려 상태엔 추천 카운트가 없다 | test_spot_detail_header_rejected_light.1.png |
| spot-detail-header-rejected-dark | SpotPublicationHeader | 위와 동일 | 윤슬 | ko_KR / .large | Dark | 390pt 고정 | Light과 동일 | test_spot_detail_header_rejected_dark.1.png |
| spot-detail-header-published-light | SpotPublicationHeader | status = .published, likeCount = 0 | 윤슬 | ko_KR / .large | Light | 390pt 고정 | 뱃지 "MY 스팟"(주황 라인). 서브타이틀이 "윤슬 · 추천 0" — 구분점은 2x2 원 `#B1B8BE`, 좌우 gap 4 | test_spot_detail_header_published_light.1.png |
| spot-detail-header-published-dark | SpotPublicationHeader | 위와 동일 | 윤슬 | ko_KR / .large | Dark | 390pt 고정 | Light과 동일 | test_spot_detail_header_published_dark.1.png |
| spot-detail-header-published-a11y | SpotPublicationHeader | status = .published, likeCount = 1234 | 윤슬 | ko_KR / .accessibilityExtraLarge | Dark | 390pt 고정 | 타이틀이 2줄로 접히고 뱃지는 첫 줄 우측에 붙어 잘리지 않는다. "추천 1234"가 축약 없이 원 숫자로 표시 | test_spot_detail_header_published_a11y.1.png |
| spot-action-row-draft-light | SpotActionButtons | status = .draft | — | ko_KR / .large | Light | 390pt 고정 | 높이 52. [길 안내 받기](주황 `#FA6133`, near_me 아이콘) 173 + [내 스팟 오픈하기](흰 `#FFFFFF`, 라벨 `#33363D`) 173, gap 12 | test_spot_action_row_draft_light.1.png |
| spot-action-row-draft-dark | SpotActionButtons | 위와 동일 | — | ko_KR / .large | Dark | 390pt 고정 | Light과 동일 | test_spot_action_row_draft_dark.1.png |
| spot-action-row-review-light | SpotActionButtons | status = .pending | — | ko_KR / .large | Light | 390pt 고정 | 우측 버튼 라벨만 "스팟 오픈 철회"로 교체, 크기·색 동일 | test_spot_action_row_review_light.1.png |
| spot-action-row-review-dark | SpotActionButtons | 위와 동일 | — | ko_KR / .large | Dark | 390pt 고정 | Light과 동일 | test_spot_action_row_review_dark.1.png |
| spot-action-row-published-light | SpotActionButtons | status = .published, canLike = true, isLiked = false | — | ko_KR / .large | Light | 390pt 고정 | 높이 56으로 커진다. [길 안내 받기] 290 + 추천 아이콘 버튼 56x56(흰 배경, thumb_up 벡터 `#33363D`), gap 12 | test_spot_action_row_published_light.1.png |
| spot-action-row-published-dark | SpotActionButtons | 위와 동일 | — | ko_KR / .large | Dark | 390pt 고정 | Light과 동일 | test_spot_action_row_published_dark.1.png |
| spot-action-row-rejected-light | SpotActionButtons | status = .rejected, canLike = false | — | ko_KR / .large | Light | 390pt 고정 | 시안 기준 published와 같은 290+56 배치. 추천 버튼은 비활성(탭 불가) 상태로 노출 | test_spot_action_row_rejected_light.1.png |
| spot-action-row-rejected-dark | SpotActionButtons | 위와 동일 | — | ko_KR / .large | Dark | 390pt 고정 | Light과 동일 | test_spot_action_row_rejected_dark.1.png |
| spot-like-button-default-light | SpotLikeButton | isLiked = false | — | ko_KR / .large | Light | 56x56 고정 | 배경 `#FFFFFF`, radius 8, thumb_up 24x24 벡터 `#33363D` | test_spot_like_button_default_light.1.png |
| spot-like-button-default-dark | SpotLikeButton | 위와 동일 | — | ko_KR / .large | Dark | 56x56 고정 | Light과 동일 | test_spot_like_button_default_dark.1.png |
| spot-like-button-active-light | SpotLikeButton | isLiked = true | — | ko_KR / .large | Light | 56x56 고정 | 배경 `#FA6133`, thumb_up 벡터 `#FFFFFF` (활성 시안 미수령분 — 프라이머리 반전으로 잠정 구현) | test_spot_like_button_active_light.1.png |
| spot-like-button-active-dark | SpotLikeButton | 위와 동일 | — | ko_KR / .large | Dark | 56x56 고정 | Light과 동일 | test_spot_like_button_active_dark.1.png |
| spot-rejection-banner-light | SpotRejectionBanner | rejectedAt = 2026-07-21, guideMessage = "선택하신 카테고리와 사진이 일치하지 않습니다." | — | ko_KR / .large | Light | 390pt 고정 | 358 폭, bg `#1E2124` 위에 `#B83311` 12% 오버레이, radius 12, padding 16/20. 1행 "26.07.21 반려됨" 13 `#B1B8BE`, 2행 사유 15 w600 `#FFFFFF`, 하단 [스팟 오픈 철회](흰) 153 + [수정 후 재신청](주황) 153 | test_spot_rejection_banner_light.1.png |
| spot-rejection-banner-dark | SpotRejectionBanner | 위와 동일 | — | ko_KR / .large | Dark | 390pt 고정 | Light과 동일 | test_spot_rejection_banner_dark.1.png |
| spot-rejection-banner-a11y | SpotRejectionBanner | guideMessage 가 60자 장문 | — | ko_KR / .accessibilityExtraLarge | Dark | 390pt 고정 | 사유가 여러 줄로 늘어나며 배너 높이가 자라고, 버튼 두 개는 잘리지 않고 아래로 밀린다 | test_spot_rejection_banner_a11y.1.png |
| spot-visibility-toggle-on-light | SpotVisibilityToggle | isPublic = true | — | ko_KR / .large | Light | 390pt 고정 | 358x76, bg `#1E2124`, radius 8. "스팟 공개" `#FFFFFF` + "ON" `#FA6133`(둘 다 17 w600), 설명 "다른 사용자에게 MY 스팟을 공개합니다." 13 `#B1B8BE`. 우측 스위치 51x31 주황, 노브 우측 | test_spot_visibility_toggle_on_light.1.png |
| spot-visibility-toggle-on-dark | SpotVisibilityToggle | 위와 동일 | — | ko_KR / .large | Dark | 390pt 고정 | Light과 동일 | test_spot_visibility_toggle_on_dark.1.png |
| spot-visibility-toggle-off-light | SpotVisibilityToggle | isPublic = false | — | ko_KR / .large | Light | 390pt 고정 | "OFF"가 회색, 설명이 "다른 사용자에게 MY 스팟이 노출되지 않습니다.", 스위치 트랙이 회색이고 노브가 좌측 | test_spot_visibility_toggle_off_light.1.png |
| spot-visibility-toggle-off-dark | SpotVisibilityToggle | 위와 동일 | — | ko_KR / .large | Dark | 390pt 고정 | Light과 동일 | test_spot_visibility_toggle_off_dark.1.png |
| spot-delete-link-light | SpotDeleteLink | — | — | ko_KR / .large | Light | 390pt 고정 | "스팟 삭제하기" 15 w400 `#E14B21`, 좌측 정렬, 상하 padding 8 | test_spot_delete_link_light.1.png |
| spot-delete-link-dark | SpotDeleteLink | — | — | ko_KR / .large | Dark | 390pt 고정 | Light과 동일 | test_spot_delete_link_dark.1.png |
| spot-sheet-open-request-light | SpotPublicationSheetContent | `.openRequest` | — | ko_KR / .large | Light | 390pt 고정 | 높이 280. 그래버 45x3 `#D9D9D9`. 타이틀 "MY 스팟을 오픈할까요?" 22 w600, 본문 3줄 15 `#B1B8BE`. 버튼 [취소] 118(hug) + [오픈 신청하기] 220(fill), gap 12 | test_spot_sheet_open_request_light.1.png |
| spot-sheet-open-request-dark | SpotPublicationSheetContent | 위와 동일 | — | ko_KR / .large | Dark | 390pt 고정 | Light과 동일 | test_spot_sheet_open_request_dark.1.png |
| spot-sheet-withdraw-light | SpotPublicationSheetContent | `.withdraw` | — | ko_KR / .large | Light | 390pt 고정 | 높이 238. 타이틀 "오픈 신청을 철회할까요?"에서 "철회"만 `#FA6133`. 본문 1줄. 버튼 169 + 169 균등, 우측 라벨 "오픈 철회하기" | test_spot_sheet_withdraw_light.1.png |
| spot-sheet-withdraw-dark | SpotPublicationSheetContent | 위와 동일 | — | ko_KR / .large | Dark | 390pt 고정 | Light과 동일 | test_spot_sheet_withdraw_dark.1.png |
| spot-sheet-delete-light | SpotPublicationSheetContent | `.delete` | — | ko_KR / .large | Light | 390pt 고정 | 높이 238. 타이틀 "MY 스팟을 삭제할까요?"에서 "삭제"만 `#FA6133`. 본문 "삭제한 스팟과 관련된 정보는 복구할 수 없어요." 버튼 169 + 169, 우측 라벨 "삭제하기" | test_spot_sheet_delete_light.1.png |
| spot-sheet-delete-dark | SpotPublicationSheetContent | 위와 동일 | — | ko_KR / .large | Dark | 390pt 고정 | Light과 동일 | test_spot_sheet_delete_dark.1.png |
| spot-sheet-open-request-a11y | SpotPublicationSheetContent | `.openRequest` | — | ko_KR / .accessibilityExtraLarge | Dark | 390pt 고정 | 본문이 5줄 이상으로 늘어 시트 높이가 자라고, 버튼 두 개가 가로로 유지되며 라벨이 잘리지 않는다 | test_spot_sheet_open_request_a11y.1.png |
| spot-open-complete-popup-light | SpotOpenCompletePopup | — | — | ko_KR / .large | Light | 390pt 고정 | 328x210, bg `#1E2124`, radius 16, padding 24/16/16/16. 타이틀 "MY 스팟 오픈 완료!" 19 w600, 본문 2줄 15 `#B1B8BE`, 하단 [확인했어요] 296x52 주황 풀폭 | test_spot_open_complete_popup_light.1.png |
| spot-open-complete-popup-dark | SpotOpenCompletePopup | 위와 동일 | — | ko_KR / .large | Dark | 390pt 고정 | Light과 동일 | test_spot_open_complete_popup_dark.1.png |
| spot-open-complete-popup-a11y | SpotOpenCompletePopup | — | — | ko_KR / .accessibilityExtraLarge | Dark | 390pt 고정 | 본문이 늘어나 팝업 높이가 자라고 버튼이 아래로 밀리며 라벨은 한 줄 유지 | test_spot_open_complete_popup_a11y.1.png |
| spot-toast-open-submitted-light | SpotPublicationToast | message = "오픈 신청이 접수되었어요." | — | ko_KR / .large | Light | 390pt 고정 | bg `#FFFFFF`, radius 8, padding 8/12, 라벨 17 w600 `#1E2124`, 폭은 텍스트에 맞춰 hug | test_spot_toast_open_submitted_light.1.png |
| spot-toast-open-submitted-dark | SpotPublicationToast | 위와 동일 | — | ko_KR / .large | Dark | 390pt 고정 | Light과 동일 | test_spot_toast_open_submitted_dark.1.png |

## 최소 커버리지 자가 점검

- [x] **상태 4종** — 공개 상태 네 가지(나만보기/검수중/반려/공개)를 헤더·액션 행에서 각각 1행씩 커버. loading/empty/error는 기존 `SpotDetailSnapshotTests`가 이미 다루므로 중복 정의하지 않음
- [x] **테마 분기** — 이 컴포넌트들은 스팟 테마에 의존하지 않는다(테마는 서브타이틀 텍스트로만 들어감). 헤더 케이스에서 "윤슬" 고정으로 두고 `—` 처리
- [x] **선택적 필드 분기** — 추천 카운트 유무(published vs rejected), 추천 버튼 유무(draft/review vs published/rejected), 스위치 ON/OFF, 추천 버튼 활성/비활성 커버
- [x] **Light/Dark** — 전 케이스 한 쌍씩. 다크 전용 팔레트라 시각 결과는 동일하지만, colorScheme 변경으로 시스템 색이 새어 들어오는 회귀를 잡기 위해 쌍으로 유지
- [x] **DynamicType `.accessibilityExtraLarge`** — 텍스트 비중이 큰 4개(헤더, 반려 배너, 바텀시트, 오픈 완료 팝업)에 각 1행

## 미확정으로 남긴 부분

표에 포함했지만 시안·정책이 확정되면 기대 결과가 바뀔 수 있는 행:

- `spot-action-row-rejected-*` — 반려 상태에 추천 버튼이 실제로 노출되는 게 맞는지 확인 필요 (기획 3.8은 "버튼 자체 없음", 시안엔 있음)
- `spot-like-button-active-*` — 추천 버튼 눌린 상태 시안 미수령. 프라이머리 반전으로 잠정 구현
- `spot-rejection-banner-*` 의 [스팟 오픈 철회] — 호출할 API가 없어 액션 미연결 (버튼은 그린다)
