# [KAN-99] SpotDetailBottomSheet — UI Test Cases

> Phase B 산출물 (Gate 1B + Gate 2). 본 표가 채워져야 Phase C(snapshot) 진입.
> 컬럼·커버리지 규칙은 `docs/phases/phase-b-ui-cases.md` 참조.
> 본 작업은 **다크 모드 전용** (Figma file이 dark만 제공, 사용자 합의). Light 행은 생성하지 않음.

## 매트릭스

| case id | 컴포넌트 | 상태/입력 조건 | 테마 | 언어 / DynamicType | Light/Dark | 디바이스 | 기대 시각 결과 | 스냅샷 파일명 |
|---|---|---|---|---|---|---|---|---|
| `kan99-sheet-chrome-dark` | SheetChromeView | 단독 렌더(콘텐츠 슬롯 빈 placeholder) | — | ko_KR / .large | Dark | iPhone 15 | gray95 배경 위 상단 중앙에 45×3 grab handle pill (#D9D9D9), 상하 8px padding. cornerRadius 20px 20px 0 0 | `kan99-sheet-chrome-dark.png` |
| `kan99-sheet-content-collapsed-not-bookmarked-dark` | SpotDetailSheetContentView | loaded(잠원 한강공원, 윤슬, 북마크 34, 2.5km, 서울시 강동구), isBookmarked=false, isAddressExpanded=false | 윤슬 | ko_KR / .large | Dark | iPhone 15 | Heading "잠원 한강공원" (gray5, 24/SemiBold), "윤슬 · 북마크 34" (gray10/Body-medium), "2.5km · 서울시 강동구 ↑"(화살표 아래 방향), 그 아래 사진 영역(높이 350, gray90), 액션 row: 주황(sunsetOrange) "길 안내 받기"(흰 텍스트) + 흰 "저장됨" 미표시 대신 "저장"(테두리 흰) — 주소 펼침 박스 **숨김** | `kan99-sheet-content-collapsed-not-bookmarked-dark.png` |
| `kan99-sheet-content-expanded-not-bookmarked-dark` | SpotDetailSheetContentView | 위와 동일하되 isAddressExpanded=true | 윤슬 | ko_KR / .large | Dark | iPhone 15 | 위 케이스 + heading과 사진 사이에 주소 펼침 박스(gray90 bg, 1px gray80 stroke, cornerRadius 8) 노출. 박스 안: "도로명" gray30 + "강동대로 51길 28 1층" gray0 + "복사" sunsetOrange / "지번" gray30 + "성내동 446-6" gray0 + "복사" sunsetOrange. 화살표 방향이 위로 (펼침 상태) | `kan99-sheet-content-expanded-not-bookmarked-dark.png` |
| `kan99-sheet-content-collapsed-bookmarked-dark` | SpotDetailSheetContentView | isBookmarked=true, isAddressExpanded=false, 그 외 동일 | 윤슬 | ko_KR / .large | Dark | iPhone 15 | 첫 케이스와 동일하되 액션 row 두 번째 버튼이 흰 배경 + 북마크 채워진 아이콘(ic_bookmark) + "저장됨"(gray80 텍스트). 첫 번째 버튼은 동일 sunsetOrange | `kan99-sheet-content-collapsed-bookmarked-dark.png` |
| `kan99-sheet-content-long-name-dark` | SpotDetailSheetContentView | 스팟 이름 매우 김(예: "잠원 한강공원 노을 명소 윤슬이 가장 아름다운 곳"), 그 외 collapsed-not-bookmarked와 동일 | 윤슬 | ko_KR / .large | Dark | iPhone 15 | Heading이 2줄 wrap, 후속 섹션이 그만큼 아래로 밀림. 시트 컨테이너는 hug content이므로 전체 시트 높이 증가. 잘림 없음 | `kan99-sheet-content-long-name-dark.png` |
| `kan99-sheet-content-dynamictype-axl-dark` | SpotDetailSheetContentView | collapsed-not-bookmarked 동일 조건 | 윤슬 | ko_KR / .accessibilityExtraLarge | Dark | iPhone 15 | 모든 텍스트(Heading/Body-medium/Body-small/Body-large-bold)가 1.5~2배 확대. heading 2~3줄 wrap. 액션 버튼 텍스트가 버튼 영역 안에 들어가는지 확인 (잘림이면 회귀) | `kan99-sheet-content-dynamictype-axl-dark.png` |
| `kan99-shell-root-medium-composed-dark` | SpotShellRootView | viewModel.presentationPhase = .sheetMedium, state = loaded(잠원 한강공원...), isBookmarked=false, isAddressExpanded=false | 윤슬 | ko_KR / .large | Dark | iPhone 15 | SheetChromeView + SpotDetailSheetContentView 결합. grab handle → heading → sub-info → distance row → 사진 → 액션 row 순. 시트 영역 외부(상단 빈 공간)는 캡쳐 범위 밖이거나 투명 처리 | `kan99-shell-root-medium-composed-dark.png` |

## 최소 커버리지 자가 점검

- [x] **상태**: loaded 정상 (loading/empty/error는 medium 시트엔 의미 없음 — fullCover의 `SpotDetailView`가 기존 스냅샷에서 커버. 본 티켓에서 신규 작성 X)
- [x] **테마 분기**: 윤슬 1종(현재 디자인에서 medium 시트의 시각이 테마와 무관 — `SpotTheme.reflection`/`sunset` 모두 동일 렌더링 가정. 변화 발견되면 행 추가)
- [x] **선택적 필드 분기**: `isAddressExpanded` true/false, `isBookmarked` true/false, 콘텐츠 길이(짧음 vs 매우 김)
- [x] **Light/Dark**: 다크 전용(사용자 합의). Light 행 0개로 의도 분리
- [x] **DynamicType**: `accessibilityExtraLarge` 1행 (`kan99-sheet-content-dynamictype-axl-dark`)

## Phase C에서 만들 스냅샷 파일

```
PickflowTests/__Snapshots__/SpotDetailBottomSheetSnapshotTests/
  ├── test_sheetChrome_dark.kan99-sheet-chrome-dark.png
  ├── test_sheetContent_collapsedNotBookmarked_dark.kan99-sheet-content-collapsed-not-bookmarked-dark.png
  ├── test_sheetContent_expandedNotBookmarked_dark.kan99-sheet-content-expanded-not-bookmarked-dark.png
  ├── test_sheetContent_collapsedBookmarked_dark.kan99-sheet-content-collapsed-bookmarked-dark.png
  ├── test_sheetContent_longName_dark.kan99-sheet-content-long-name-dark.png
  ├── test_sheetContent_dynamicTypeAXL_dark.kan99-sheet-content-dynamictype-axl-dark.png
  └── test_shellRoot_mediumComposed_dark.kan99-shell-root-medium-composed-dark.png
```

> phase=`.sheetLarge` / `.fullCover` 콘텐츠는 `SpotDetailView`의 기존 스냅샷(`SpotDetailSnapshotTests`)에 의존. 본 티켓 신규 작성 없음.
