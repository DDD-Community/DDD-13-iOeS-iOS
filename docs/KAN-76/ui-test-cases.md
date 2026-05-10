# [KAN-76] 로그인 화면 UI 테스트 케이스

> **Phase B 산출물 (Gate 2)**. Phase A(ViewModel TDD) 완료 후 작성.
> 작성 가이드: `docs/phases/phase-b-ui-cases.md`.

## 매트릭스

| case id | 컴포넌트 | 상태/입력 조건 | 테마 | 언어 / DynamicType | Light/Dark | 디바이스 | 기대 시각 결과 | 스냅샷 파일명 |
|---|---|---|---|---|---|---|---|---|
| login-root-idle-dark | 루트 프레임 | `isLoading=false`, `errorMessage=nil`, `didSignInSucceed=false` | — | ko_KR / .large | Dark | iPhone 17 | 390pt 폭 기준 전체 화면이 safe area까지 4-stop linear gradient로 채워지고, 중앙 콘텐츠와 하단 CTA가 Figma 간격으로 배치된다. | test_login_root_idle_dark.login-root-idle-dark.png |
| login-header-idle-dark | 상단 PICKFLOW 헤더 | 기본 idle 상태 | — | ko_KR / .large | Dark | iPhone 17 | status bar 아래 좌측 16pt inset에 140x32 PICKFLOW wordmark가 보이고, 우측 거리순 placeholder는 렌더되지 않는다. | test_login_header_idle_dark.login-header-idle-dark.png |
| login-center-content-idle-dark | 중앙 스택 | 기본 idle 상태 | — | ko_KR / .large | Dark | iPhone 17 | 60x60 흰 rounded rect 안에 40x40 flare 아이콘이 있고, 헤드라인 2줄과 서브헤드 2줄이 가운데 정렬로 겹침 없이 표시된다. | test_login_center_content_idle_dark.login-center-content-idle-dark.png |
| login-cta-idle-dark | 하단 CTA 스택 | 기본 idle 상태 | — | ko_KR / .large | Dark | iPhone 17 | 카카오/Apple 버튼이 각 56pt 높이, cornerRadius 8, 12pt 간격으로 쌓이고, 아래에 underline 처리된 "비회원으로 시작하기" 링크가 보인다. | test_login_cta_idle_dark.login-cta-idle-dark.png |
| login-cta-kakao-loading-dark | 카카오 버튼 | 카카오 로그인 task 진행 중, `isLoading=true`, active provider=`kakao` | — | ko_KR / .large | Dark | iPhone 17 | 카카오 버튼 내부 라벨 대신 진행 표시가 보이며 중복 탭을 막는 disabled 상태로 보인다. Apple 버튼과 비회원 링크는 레이아웃 위치가 흔들리지 않는다. | test_login_cta_kakao_loading_dark.login-cta-kakao-loading-dark.png |
| login-cta-apple-loading-dark | Apple 버튼 | Apple 로그인 task 진행 중, `isLoading=true`, active provider=`apple` | — | ko_KR / .large | Dark | iPhone 17 | Apple 버튼 내부 라벨 대신 진행 표시가 보이며 흰 버튼 배경과 8pt radius는 유지된다. 카카오 버튼과 비회원 링크는 레이아웃 위치가 흔들리지 않는다. | test_login_cta_apple_loading_dark.login-cta-apple-loading-dark.png |
| login-alert-error-dark | 루트 프레임 | `errorMessage="로그인에 실패했어요"` | — | ko_KR / .large | Dark | iPhone 17 | 로그인 화면 위에 시스템 alert가 표시되고 제목은 "로그인 실패", 메시지는 "로그인에 실패했어요", 액션은 "확인" 한 개다. | test_login_alert_error_dark.login-alert-error-dark.png |
| login-guest-requested-dark | 비회원 링크 | `continueAsGuestTapped()` 후 `didRequestGuestEntry=true` | — | ko_KR / .large | Dark | iPhone 17 | 비회원 링크의 시각 상태는 idle과 동일하며, 라우팅 셸 상태 변경 때문에 버튼 스택 위치나 텍스트 스타일이 변하지 않는다. | test_login_guest_requested_dark.login-guest-requested-dark.png |
| login-root-idle-light-forced-dark | 루트 프레임 | 시스템 Light 환경에서 로그인 화면 렌더 | — | ko_KR / .large | Light | iPhone 17 | 앱 환경이 Light여도 로그인 화면은 `.preferredColorScheme(.dark)` 정책으로 dark gradient와 white text를 유지한다. | test_login_root_idle_light_forced_dark.login-root-idle-light-forced-dark.png |
| login-root-accessibility-extra-large-dark | 루트 프레임 | 기본 idle 상태 | — | ko_KR / .accessibilityExtraLarge | Dark | iPhone 17 | Dynamic Type 확대에서도 헤드라인/서브헤드/CTA 텍스트가 서로 겹치지 않고 하단 링크가 화면 밖으로 밀리지 않는다. | test_login_root_accessibility_extra_large_dark.login-root-accessibility-extra-large-dark.png |
| login-root-ipad-dark | 루트 프레임 | 기본 idle 상태 | — | ko_KR / .large | Dark | iPad Air 11-inch (M4) | iPad 폭에서도 배경은 전체를 채우고, 중앙 콘텐츠와 CTA는 390pt급 로그인 화면 규격을 유지하며 과도하게 늘어나지 않는다. | test_login_root_ipad_dark.login-root-ipad-dark.png |

## 최소 커버리지 점검

- [x] 기본 렌더: `login-root-idle-dark`, `login-header-idle-dark`, `login-center-content-idle-dark`, `login-cta-idle-dark`
- [x] loading: `login-cta-kakao-loading-dark`, `login-cta-apple-loading-dark`
- [x] error: `login-alert-error-dark`
- [x] 선택적 이벤트: `login-guest-requested-dark`
- [x] Light/Dark 정책: `login-root-idle-light-forced-dark`
- [x] DynamicType: `login-root-accessibility-extra-large-dark`
- [x] iPad: `login-root-ipad-dark`

## 디바이스/환경 고정값

- 기본: iPhone 17, iOS 26.4 simulator, dark color scheme 강제, Pretendard 폰트 등록 후
- locale: `ko_KR`
- 비교 정밀도: `precision: 0.99`, `perceptualPrecision: 0.98`
