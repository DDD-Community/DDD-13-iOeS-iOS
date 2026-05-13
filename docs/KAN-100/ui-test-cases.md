# [KAN-100] 온보딩 UI 테스트 케이스 매트릭스

> **이 문서는 Phase B의 산출물이다.** Phase C 스냅샷 매트릭스는 이 표를 1:1 베이스로 작성한다.
> 작성 가이드 / 8컬럼 정의 / 최소 커버리지 기준: `docs/phases/phase-b-ui-cases.md`.

**상태**: 🟢 작성 완료 (Phase A 종료 후 작성)
**소스 프롬프트**: `docs/KAN-100/onboarding-implementation-prompt.md`
**스코프 특이사항**: API 호출 없음 → loading/error/empty 상태 부재. 페이지 4분기 + 테마(orange/blue) 분기 + 접근성이 커버리지 축.

---

## 매트릭스

| case id | 컴포넌트 | 상태/입력 조건 | 테마 | 언어 / DynamicType | Light/Dark | 디바이스 | 기대 시각 결과 | 스냅샷 파일명 |
|---|---|---|---|---|---|---|---|---|
| `onboarding-screen-page0-light` | Page 0 (전체) | `currentIndex=0`, defaultPages | orange | ko_KR / .large | Light | iPhone 15 | 상단 오렌지 배경에 `onboarding_0` PDF 일러스트, 좌상단 PICKFLOW 워드마크, 하단 다크 패널에 2줄 타이틀 "흩어진 포토스팟,\n이제 한 번에 찾을 수 있어요"(흰색+오렌지 강조 "한 번에 찾을 수 있어요"), 서브타이틀 2줄 그레이, 인디케이터 4개 중 첫 번째가 오렌지 pill, "시작하기" 풀와이드 오렌지 CTA | `onboarding-screen-page0-light.png` |
| `onboarding-screen-page0-dark` | Page 0 (전체) | `currentIndex=0`, defaultPages | orange | ko_KR / .large | Dark | iPhone 15 | Light와 동일 레이아웃. 다크 모드 어셋 컬러 미세 차이만 발생 | `onboarding-screen-page0-dark.png` |
| `onboarding-screen-page1-light` | Page 1 (전체) | `currentIndex=1`, defaultPages | orange | ko_KR / .large | Light | iPhone 15 | 상단 오렌지 배경에 `onboarding_1` 일러스트(폰 mockup + chat bubble), 하단 패널 타이틀 "나만의 스팟을\n기록하고 공유해보세요"(흰색+오렌지 강조 "나만의 스팟을"), 인디케이터 두 번째가 활성 | `onboarding-screen-page1-light.png` |
| `onboarding-screen-page1-dark` | Page 1 (전체) | `currentIndex=1`, defaultPages | orange | ko_KR / .large | Dark | iPhone 15 | Light와 동일 레이아웃, 다크 모드 | `onboarding-screen-page1-dark.png` |
| `onboarding-screen-page2-light` | Page 2 (전체) | `currentIndex=2`, defaultPages | orange | ko_KR / .large | Light | iPhone 15 | 상단 오렌지 배경에 `onboarding_2` 일러스트(노을 chip + 3장 가로 이미지), 하단 패널 타이틀 "하루의 끝자락에서,\n노을이 가장 아름다운 순간"(2번째 줄 전체 오렌지 강조), 인디케이터 세 번째 활성 | `onboarding-screen-page2-light.png` |
| `onboarding-screen-page2-dark` | Page 2 (전체) | `currentIndex=2`, defaultPages | orange | ko_KR / .large | Dark | iPhone 15 | Light와 동일 레이아웃, 다크 모드 | `onboarding-screen-page2-dark.png` |
| `onboarding-screen-page3-light` | Page 3 (전체) | `currentIndex=3`, defaultPages | blue | ko_KR / .large | Light | iPhone 15 | 상단 다크블루 배경에 `onboarding_3` 일러스트(윤슬 outlined-blue chip + 3장 가로 이미지), 하단 패널 타이틀 "물가에 빛이 닿을 때,\n윤슬이 가장 반짝이는 순간"(2번째 줄 전체 블루 강조), 인디케이터 네 번째 활성(블루 액센트), CTA는 동일 오렌지 | `onboarding-screen-page3-light.png` |
| `onboarding-screen-page3-dark` | Page 3 (전체) | `currentIndex=3`, defaultPages | blue | ko_KR / .large | Dark | iPhone 15 | Light와 동일 레이아웃, 다크 모드 | `onboarding-screen-page3-dark.png` |
| `onboarding-indicator-page0-light` | 페이지 인디케이터 | `currentIndex=0` | orange | ko_KR / .large | Light | iPhone 15 | 4개 도트 가로 중앙 정렬. 첫 번째가 오렌지 pill(가로 늘어남), 나머지 3개는 작은 다크 그레이 원 | `onboarding-indicator-page0-light.png` |
| `onboarding-indicator-page1-light` | 페이지 인디케이터 | `currentIndex=1` | orange | ko_KR / .large | Light | iPhone 15 | 두 번째 도트만 오렌지 pill, 나머지 3개는 다크 그레이 원 | `onboarding-indicator-page1-light.png` |
| `onboarding-indicator-page2-light` | 페이지 인디케이터 | `currentIndex=2` | orange | ko_KR / .large | Light | iPhone 15 | 세 번째 도트만 오렌지 pill, 나머지 3개는 다크 그레이 원 | `onboarding-indicator-page2-light.png` |
| `onboarding-indicator-page3-light` | 페이지 인디케이터 | `currentIndex=3` | blue | ko_KR / .large | Light | iPhone 15 | 네 번째 도트만 활성 pill, 나머지 3개는 다크 그레이 원. **활성 도트 색은 Page 3 액센트 = 블루** (테마에 따라 액티브 도트 색이 달라지는지 시안 재확인) | `onboarding-indicator-page3-light.png` |
| `onboarding-panel-page0-light` | 하단 패널 | `currentIndex=0`, defaultPages | orange | ko_KR / .large | Light | iPhone 15 | 다크 배경 패널만 단독 캡처. 타이틀/서브타이틀/인디케이터/CTA 4요소가 가로 중앙 정렬. 강조 색 적용 영역(오렌지 "한 번에 찾을 수 있어요")이 정확히 해당 범위만 색이 다름 | `onboarding-panel-page0-light.png` |
| `onboarding-panel-page0-dark` | 하단 패널 | `currentIndex=0`, defaultPages | orange | ko_KR / .large | Dark | iPhone 15 | Light와 동일 레이아웃, 다크 모드 | `onboarding-panel-page0-dark.png` |
| `onboarding-panel-page3-light` | 하단 패널 | `currentIndex=3`, defaultPages | blue | ko_KR / .large | Light | iPhone 15 | 강조 색이 블루(`onboardingAccentBlue`)로 적용된 패널. 강조 영역 "윤슬이 가장 반짝이는 순간". CTA 배경은 그대로 오렌지 | `onboarding-panel-page3-light.png` |
| `onboarding-panel-page3-dark` | 하단 패널 | `currentIndex=3`, defaultPages | blue | ko_KR / .large | Dark | iPhone 15 | Light와 동일 레이아웃, 다크 모드 | `onboarding-panel-page3-dark.png` |
| `onboarding-cta-light` | 시작하기 CTA | 단독, 활성 상태 | — | ko_KR / .large | Light | iPhone 15 | 풀와이드 직사각형 버튼, 오렌지 배경, 가운데 흰색 "시작하기" 라벨. corner radius는 Figma 확정값 적용 | `onboarding-cta-light.png` |
| `onboarding-cta-dark` | 시작하기 CTA | 단독, 활성 상태 | — | ko_KR / .large | Dark | iPhone 15 | Light와 동일. 다크 모드에서도 액센트 오렌지 유지 | `onboarding-cta-dark.png` |
| `onboarding-screen-page0-a11y` | Page 0 (전체) | `currentIndex=0` | orange | ko_KR / .accessibilityExtraLarge | Light | iPhone 15 | 타이틀/서브타이틀/CTA 라벨이 큰 폰트로 렌더링. 텍스트 잘림 0, 줄바꿈은 자연스럽게 추가 줄로 확장. 일러스트와 패널 비율은 SwiftUI 기본 동작에 위임 | `onboarding-screen-page0-a11y.png` |
| `onboarding-screen-page3-a11y` | Page 3 (전체) | `currentIndex=3` | blue | ko_KR / .accessibilityExtraLarge | Light | iPhone 15 | 블루 강조 타이틀이 큰 폰트로 렌더링. 강조 부분 색 유지. 텍스트 잘림 0 | `onboarding-screen-page3-a11y.png` |

---

## 최소 커버리지 자가 점검

- [x] **상태 4종**: 이 화면은 API 무관 정적 컨텐츠 → loading/empty/error 부재. loaded(정상) 단일 상태에서 페이지 4분기로 대체 (스킬 가이드 "화면이 가질 수 있는 만큼만"에 부합)
- [x] **테마 분기**: orange(Page 0~2)·blue(Page 3) 분기마다 행 존재. 패널·인디케이터·전체 화면에서 둘 다 다룸
- [x] **선택적 필드 분기**: 본 화면은 모두 고정 컨텐츠라 선택 필드 없음
- [x] **Light/Dark**: 핵심 케이스(Page 0~3 전체, 패널 Page 0/3, CTA) 모두 한 쌍씩 분리
- [x] **DynamicType `.accessibilityExtraLarge`**: 텍스트 비중이 큰 페이지 0(오렌지)·페이지 3(블루) 각 1행 추가

총 20행. 작은 화면(~15행) ~ 보통(~30행) 범위.

---

## 진입/종료 조건

- 진입: Phase A (ViewModel TDD) 종료 조건 통과 ✅
- 종료:
  - [x] `<!-- TODO -->` 0개
  - [x] 8컬럼 모두 채움
  - [x] 모든 행 `스냅샷 파일명` 결정
  - [x] 위 5개 자가 점검 통과
  - [x] 리뷰어가 표만 읽고 어떤 스냅샷이 찍힐지 그릴 수 있음

---

## 메모 / Phase C 결과

- `onboarding-indicator-page3-light`: **(a) 옵션 채택** — 활성 도트 색이 페이지 액센트를 따른다(Page 3은 블루). Phase C 스냅샷 시각 비교에서 윤슬 강조와 도트가 같은 블루로 통일된 모습이 시안 의도에 부합. 베이스라인 PNG로 확정
- 다크 모드 분기 색: 베이스라인 record 시점에 라이트와 동일 hex로 캡처됨(asset에 Dark variant 미정의). 추후 Figma 권한+§9.1 batch 시점에 다크 톤이 정의되면 그 PR에서 record 갱신 + 시각 diff 첨부
- 접근성 케이스(Page 0/3 a11y): iPhone 13 Pro layout에서 텍스트 잘림 없이 렌더링 확인됨. ScrollView 래핑 합의 항목은 불요. 베이스라인 PNG로 확정
