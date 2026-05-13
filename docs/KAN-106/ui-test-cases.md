# [KAN-106] 온보딩 일러스트 — UI Test Cases

> Phase B 산출물. Phase C 스냅샷 매트릭스의 단일 진실 소스.
>
> 본 표는 **신규 추가되는 컴포넌트 단위 스냅샷**(`OnboardingIllustration` 단독)을 정의한다.
> 기존 `OnboardingSnapshotTests`의 화면 전체(`onboarding-screen-pageN-light/dark`)는 통이미지 → 그라데이션+개별 이미지 합성으로 바뀌므로 **기록 재생성** 대상이지만, 본 표에서는 다루지 않는다 (KAN-100에서 정의된 케이스 그대로 유지, 스냅샷만 갱신).

## 컴포넌트 단위 케이스 (신규)

| case id | 컴포넌트 | 상태/입력 조건 | 테마 | 언어 / DynamicType | Light/Dark | 디바이스 | 기대 시각 결과 | 스냅샷 파일명 |
|---|---|---|---|---|---|---|---|---|
| onboarding-illustration-step0-light | OnboardingIllustration | page = defaultPages[0], 정적 | orange | ko_KR / .large | Light | iPhone 13 Pro | 따뜻한 오렌지 그라데이션(top → bottomTrailing, 0xC96A35 → 0xE5926A) 위로 `onboarding_0_iphone` 아이폰 목업이 하단 중앙 정렬 | onboarding-illustration-step0-light.png |
| onboarding-illustration-step0-dark | OnboardingIllustration | page = defaultPages[0], 정적 | orange | ko_KR / .large | Dark | iPhone 13 Pro | Light과 동일 (그라데이션과 이미지가 colorScheme에 비의존) | onboarding-illustration-step0-dark.png |
| onboarding-illustration-step1-light | OnboardingIllustration | page = defaultPages[1], 정적 | orange | ko_KR / .large | Light | iPhone 13 Pro | Step 0과 동일 그라데이션, 다른 아이폰 목업(`onboarding_1_iphone`) | onboarding-illustration-step1-light.png |
| onboarding-illustration-step1-dark | OnboardingIllustration | page = defaultPages[1], 정적 | orange | ko_KR / .large | Dark | iPhone 13 Pro | Light과 동일 (비의존) | onboarding-illustration-step1-dark.png |
| onboarding-illustration-step2-light | OnboardingIllustration | page = defaultPages[2], 캐러셀 `isAnimating = false`, `initialOffset = 0` | orange | ko_KR / .large | Light | iPhone 13 Pro | 따뜻한 다크 그라데이션(top → bottom, 0x0B0B10 → 0x1A1410). 캐러셀 3장 가로 배치, 가운데(`onboarding_2_pic_1`) 100% 너비, 좌(`pic_0`)/우(`pic_2`) 0.8배 너비, 간격 12pt, 세로 중앙 정렬 | onboarding-illustration-step2-light.png |
| onboarding-illustration-step2-dark | OnboardingIllustration | 위와 동일 | orange | ko_KR / .large | Dark | iPhone 13 Pro | Light과 동일 (비의존) | onboarding-illustration-step2-dark.png |
| onboarding-illustration-step3-light | OnboardingIllustration | page = defaultPages[3], 캐러셀 `isAnimating = false`, `initialOffset = 0` | blue | ko_KR / .large | Light | iPhone 13 Pro | 차가운 다크 그라데이션(top → bottom, 0x0E1218 → 0x162536). Step 2와 다른 배경. 캐러셀은 `onboarding_3_pic_0/1/2`, 사이즈 비율 동일 | onboarding-illustration-step3-light.png |
| onboarding-illustration-step3-dark | OnboardingIllustration | 위와 동일 | blue | ko_KR / .large | Dark | iPhone 13 Pro | Light과 동일 (비의존) | onboarding-illustration-step3-dark.png |

## 최소 커버리지 자가 점검

- [x] 상태 4종 — illustration은 단일 정적 상태만 가짐 (loading/empty/error 해당 없음, 캐러셀 동적 상태는 스코프 밖)
- [x] 테마 분기 — orange / blue 모두 커버 (Step 0/1/2 = orange, Step 3 = blue)
- [x] 선택적 필드 분기 — 캐러셀 유무(Step 0/1 vs Step 2/3) 커버
- [x] Light/Dark — 각 페이지마다 한 쌍씩 (총 8행)
- [x] DynamicType `.accessibilityExtraLarge` — illustration은 텍스트 없음. 본 표에서는 생략. 기존 `OnboardingSnapshotTests`의 `test_onboarding_screen_pageN_a11y`가 화면 전체 a11y를 이미 커버

## 후속 / 영향 받는 기존 스냅샷 (KAN-100 정의)

> 본 작업으로 시각이 바뀌므로 **기록 재생성** 필요. 케이스 정의는 KAN-100에서 그대로 유지하고 PNG만 새로 record.

- `onboarding-screen-page0/1/2/3-light/dark` (8개) — illustration이 그라데이션+이미지 합성으로 바뀜
- `onboarding-screen-page0-a11y`, `onboarding-screen-page3-a11y` (2개) — 동일 이유
- `onboardingView-page0-light`, `onboardingView-page3-light` (2개) — 동일 이유
- panel/indicator/cta 케이스는 영향 없음 (illustration 외부)

총 신규 8 + 재기록 12 = **20개 스냅샷 PNG**가 Phase C 산출물.
