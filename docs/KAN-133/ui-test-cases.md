# [KAN-133] 공지사항 UI 테스트 케이스 (Phase B 산출물)

> Phase C(스냅샷)의 단일 진실 소스. 각 행 = 스냅샷 1장.
> 고정값: locale `ko_KR`, layout `.fixed(width: 393, height: 852)`, DynamicType 기본 `.large`.
> Light/Dark는 행 분리(앱은 다크 고정 톤이나 컨벤션상 둘 다 기록 — 동일 결과여도 별도 파일).
> 운용 규칙: `docs/phases/phase-b-ui-cases.md`.
> **실제 파일 경로**: swift-snapshot-testing 기본 네이밍 → `PickflowTests/__Snapshots__/NoticeSnapshotTests/test_<case-id를 _로>.1.png`. 예) `notice-list-loaded-light` → `test_notice_list_loaded_light.1.png` (전 20장 기록 완료).

## 리스트 화면 (NoticeListView)

| case id | 컴포넌트 | 상태/입력 조건 | 테마 | 언어 / DynamicType | Light/Dark | 디바이스 | 기대 시각 결과 | 스냅샷 파일명 |
|---|---|---|---|---|---|---|---|---|
| notice-list-loaded-light | NoticeListView | loaded(3건: 긴제목/[공지]/단문, content 있음) | — | ko_KR / .large | Light | 393×852 | 네비바 "공지사항"+뒤로가기, 항목 3개 각 제목(gray0)+본문 미리보기 1줄(gray30, 말줄임)+날짜 2026.05.09(gray40), 항목 사이 gray90 구분선 | notice-list-loaded-light.png |
| notice-list-loaded-dark | NoticeListView | loaded(3건) | — | ko_KR / .large | Dark | 393×852 | 위와 동일 | notice-list-loaded-dark.png |
| notice-list-loaded-a11y | NoticeListView | loaded(3건) | — | ko_KR / .accessibilityExtraLarge | Light | 393×852 | 제목/미리보기/날짜 폰트 확대, 제목 2줄·미리보기 1줄 말줄임 유지, 레이아웃 깨짐 없음 | notice-list-loaded-a11y.png |
| notice-list-no-preview-light | NoticeRowView | loaded(content nil 2건) | — | ko_KR / .large | Light | 393×852 | content 없으면 미리보기 줄 생략, 제목+날짜만 | notice-list-no-preview-light.png |
| notice-list-no-preview-dark | NoticeRowView | loaded(content nil) | — | ko_KR / .large | Dark | 393×852 | 위와 동일 | notice-list-no-preview-dark.png |
| notice-list-longtitle-light | NoticeRowView | loaded(제목 3줄 분량 1건) | — | ko_KR / .large | Light | 393×852 | 제목이 2줄에서 말줄임(…), 3번째 줄 미노출, 날짜 정상 | notice-list-longtitle-light.png |
| notice-list-longtitle-dark | NoticeRowView | loaded(긴제목 1건) | — | ko_KR / .large | Dark | 393×852 | 위와 동일 | notice-list-longtitle-dark.png |
| notice-list-empty-light | NoticeListView | empty | — | ko_KR / .large | Light | 393×852 | 네비바만, 중앙에 "등록된 공지사항이 없어요" 안내(gray40), 항목 없음 | notice-list-empty-light.png |
| notice-list-empty-dark | NoticeListView | empty | — | ko_KR / .large | Dark | 393×852 | 위와 동일 | notice-list-empty-dark.png |
| notice-list-loading-light | NoticeListView | loading | — | ko_KR / .large | Light | 393×852 | 네비바 + 중앙 ProgressView(gray0), 항목 없음 | notice-list-loading-light.png |
| notice-list-loading-dark | NoticeListView | loading | — | ko_KR / .large | Dark | 393×852 | 위와 동일 | notice-list-loading-dark.png |
| notice-list-failed-light | NoticeListView | failed("공지사항을 불러오지 못했어요") | — | ko_KR / .large | Light | 393×852 | 네비바 + 중앙 에러 문구 + "다시 시도" 버튼 | notice-list-failed-light.png |
| notice-list-failed-dark | NoticeListView | failed(동일) | — | ko_KR / .large | Dark | 393×852 | 위와 동일 | notice-list-failed-dark.png |

## 상세 화면 (NoticeDetailView)

| case id | 컴포넌트 | 상태/입력 조건 | 테마 | 언어 / DynamicType | Light/Dark | 디바이스 | 기대 시각 결과 | 스냅샷 파일명 |
|---|---|---|---|---|---|---|---|---|
| notice-detail-loaded-long-light | NoticeDetailView | loaded(긴 본문, 여러 줄바꿈) | — | ko_KR / .large | Light | 393×852 | 상단 제목(gray0)+날짜(gray40), gray80 구분선, 본문영역 gray90 배경, 본문(gray30) 줄바꿈 유지 | notice-detail-loaded-long-light.png |
| notice-detail-loaded-long-dark | NoticeDetailView | loaded(긴 본문) | — | ko_KR / .large | Dark | 393×852 | 위와 동일 | notice-detail-loaded-long-dark.png |
| notice-detail-loaded-long-a11y | NoticeDetailView | loaded(긴 본문) | — | ko_KR / .accessibilityExtraLarge | Light | 393×852 | 제목/본문 폰트 확대, 줄바꿈·스크롤 유지, 잘림 없음 | notice-detail-loaded-long-a11y.png |
| notice-detail-loaded-short-light | NoticeDetailView | loaded(짧은 본문 1줄) | — | ko_KR / .large | Light | 393×852 | 제목+날짜+짧은 본문, 하단 여백 | notice-detail-loaded-short-light.png |
| notice-detail-loaded-short-dark | NoticeDetailView | loaded(짧은 본문) | — | ko_KR / .large | Dark | 393×852 | 위와 동일 | notice-detail-loaded-short-dark.png |
| notice-detail-loading-light | NoticeDetailView | loading | — | ko_KR / .large | Light | 393×852 | 네비바 + 중앙 ProgressView | notice-detail-loading-light.png |
| notice-detail-loading-dark | NoticeDetailView | loading | — | ko_KR / .large | Dark | 393×852 | 위와 동일 | notice-detail-loading-dark.png |
| notice-detail-failed-light | NoticeDetailView | failed("공지사항을 불러오지 못했어요") | — | ko_KR / .large | Light | 393×852 | 네비바 + 중앙 에러 문구 + "다시 시도" 버튼 | notice-detail-failed-light.png |
| notice-detail-failed-dark | NoticeDetailView | failed(동일) | — | ko_KR / .large | Dark | 393×852 | 위와 동일 | notice-detail-failed-dark.png |

## 최소 커버리지 자가 점검

- [x] 상태 4종: loading / loaded / empty(리스트만, 상세는 해당 없음) / failed
- [x] 테마 분기: 없음(공지사항은 도메인 테마 분기 없음) → 전 행 `—`
- [x] 선택적 필드 분기: 리스트 제목 2줄 말줄임(longtitle), 상세 본문 길이(long/short)
- [x] Light/Dark: 시나리오마다 쌍으로 분리
- [x] DynamicType .accessibilityExtraLarge: 리스트 1행 + 상세 1행
