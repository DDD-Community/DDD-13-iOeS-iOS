# [KAN-54] My Profile UI Test Cases

> **Phase B 산출물.** Phase A 종료 후 작성. 운용 디테일은 `docs/phases/phase-b-ui-cases.md` 참조.
>
> Phase C의 swift-snapshot-testing 케이스는 이 표를 단일 진실 소스로 삼는다.

## 8컬럼 표

| case id | 컴포넌트 | 상태/입력 조건 | 테마 | 언어/DynamicType | Light/Dark | 디바이스 | 기대 시각 결과 | 스냅샷 파일명 |
|---|---|---|---|---|---|---|---|---|
| my-profile-signedout-light | 비로그인 마이프로필 | signedOut | — | ko_KR / .large | Light | iPhone 17 | 검은 배경, 상단 좌측 PICKFLOW 워드마크(흰), 중앙 상단 "마이페이지 이용을 위해 로그인이 필요해요"(bold), 부제 회색 2줄, 아래 카카오 노란 버튼·Apple 흰 버튼(풀폭), 하단 탭바 "마이" 활성 | my-profile-signedout-light.png |
| my-profile-signedout-dark | 비로그인 마이프로필 | signedOut | — | ko_KR / .large | Dark | iPhone 17 | Light와 동일 배치 (다크 모드 배경색 확인) | my-profile-signedout-dark.png |
| my-profile-signedout-a11y | 비로그인 마이프로필 | signedOut | — | ko_KR / .accessibilityExtraLarge | Light | iPhone 17 | 타이틀·부제 텍스트 확대, 버튼 라벨 잘림 없이 줄바꿈 | my-profile-signedout-a11y.png |
| my-profile-loading-light | 로그인 마이프로필 | loading | — | ko_KR / .large | Light | iPhone 17 | 화면 중앙 로딩 인디케이터, 콘텐츠 영역 비어있음 | my-profile-loading-light.png |
| my-profile-loading-dark | 로그인 마이프로필 | loading | — | ko_KR / .large | Dark | iPhone 17 | 다크 배경 + 중앙 로딩 인디케이터 | my-profile-loading-dark.png |
| my-profile-signedin-noimage-light | 로그인 마이프로필 | signedIn (profileImageURL nil) | — | ko_KR / .large | Light | iPhone 17 | 프로필 이미지 자리 기본 placeholder, 닉네임 표시, 메뉴 리스트 표시, 계정 관리 셀 visible | my-profile-signedin-noimage-light.png |
| my-profile-signedin-noimage-dark | 로그인 마이프로필 | signedIn (profileImageURL nil) | — | ko_KR / .large | Dark | iPhone 17 | 다크 배경 + placeholder + 닉네임 + 메뉴 | my-profile-signedin-noimage-dark.png |
| my-profile-signedin-withimage-light | 로그인 마이프로필 | signedIn (profileImageURL 있음) | — | ko_KR / .large | Light | iPhone 17 | 실제 프로필 이미지 동그랗게 표시, 닉네임·메뉴 동일 | my-profile-signedin-withimage-light.png |
| my-profile-signedin-withimage-dark | 로그인 마이프로필 | signedIn (profileImageURL 있음) | — | ko_KR / .large | Dark | iPhone 17 | 다크 배경 + 실제 프로필 이미지 | my-profile-signedin-withimage-dark.png |
| my-profile-failed-light | 로그인 마이프로필 | failed (네트워크 에러) | — | ko_KR / .large | Light | iPhone 17 | 에러 메시지 텍스트 노출, 재시도 영역 또는 빈 화면 | my-profile-failed-light.png |
| my-profile-failed-dark | 로그인 마이프로필 | failed (네트워크 에러) | — | ko_KR / .large | Dark | iPhone 17 | 다크 배경 + 에러 메시지 | my-profile-failed-dark.png |
| account-mgmt-idle-light | 계정관리 | 초기 loaded (저장 비활성) | — | ko_KR / .large | Light | iPhone 17 | 상단 "계정 관리" 타이틀·저장(회색 비활성), 프로필이미지+카메라 오버레이, "닉네임" 라벨+편집 필드(capybara123), "연결된 소셜" + "카카오로 로그인됨", 로그아웃·회원탈퇴(빨강) 텍스트 | account-mgmt-idle-light.png |
| account-mgmt-idle-dark | 계정관리 | 초기 loaded (저장 비활성) | — | ko_KR / .large | Dark | iPhone 17 | 다크 배경 + 동일 구성, 필드 배경 어두운 회색 | account-mgmt-idle-dark.png |
| account-mgmt-dirty-light | 계정관리 | 닉네임 변경됨 (저장 활성) | — | ko_KR / .large | Light | iPhone 17 | "저장" 버튼/라벨 활성(흰색 or 강조색), 닉네임 필드에 새 값 | account-mgmt-dirty-light.png |
| account-mgmt-dirty-dark | 계정관리 | 닉네임 변경됨 (저장 활성) | — | ko_KR / .large | Dark | iPhone 17 | 다크 배경 + 저장 활성 | account-mgmt-dirty-dark.png |
| account-mgmt-logout-dialog-light | 로그아웃 확인 다이얼로그 | logoutState = .confirming | — | ko_KR / .large | Light | iPhone 17 | 계정관리 화면 dim된 배경 위 카드 모달: "잠시 로그아웃하시겠어요?" 타이틀 + 안내 본문 + 좌측 취소(흰) / 우측 로그아웃(주황) 버튼 동일 크기 | account-mgmt-logout-dialog-light.png |
| account-mgmt-logout-dialog-dark | 로그아웃 확인 다이얼로그 | logoutState = .confirming | — | ko_KR / .large | Dark | iPhone 17 | 다크 배경 dim + 카드 어두운 회색 + 동일 구성 | account-mgmt-logout-dialog-dark.png |
| account-mgmt-logout-processing-light | 계정관리 | logoutState = .processing | — | ko_KR / .large | Light | iPhone 17 | 로그아웃 처리 중 로딩 인디케이터 또는 버튼 비활성 표시 | account-mgmt-logout-processing-light.png |
| account-mgmt-a11y | 계정관리 | 초기 loaded | — | ko_KR / .accessibilityExtraLarge | Light | iPhone 17 | 닉네임·소셜 라벨 텍스트 확대, 필드 높이 늘어나도 레이아웃 유지 | account-mgmt-a11y.png |
| withdrawal-initial-light | 회원탈퇴 - 사유 미선택 | step = .input, 사유 미선택, 동의 미체크 | — | ko_KR / .large | Light | iPhone 17 | "회원탈퇴" 타이틀, 유의사항 안내 박스(주황 강조 텍스트), "어떤 점이 아쉬우셨나요?" 섹션, 드롭다운 닫힘 + "탈퇴 사유를 선택해주세요" placeholder + ▼, 동의 체크박스 빈 사각, "탈퇴하기" 버튼 회색 비활성 | withdrawal-initial-light.png |
| withdrawal-initial-dark | 회원탈퇴 - 사유 미선택 | step = .input, 사유 미선택, 동의 미체크 | — | ko_KR / .large | Dark | iPhone 17 | 다크 배경 + 동일 구성, 안내 박스 어두운 배경 | withdrawal-initial-dark.png |
| withdrawal-dropdown-open-light | 회원탈퇴 - 드롭다운 펼침 | step = .input, isDropdownOpen = true | — | ko_KR / .large | Light | iPhone 17 | 드롭다운 카드 inline 펼침: 7개 사유 행 표시("원하는 스팟이 부족해요"~"기타"), 선택 없으므로 모두 기본색, 상단 chevron ▲ | withdrawal-dropdown-open-light.png |
| withdrawal-dropdown-open-dark | 회원탈퇴 - 드롭다운 펼침 | step = .input, isDropdownOpen = true | — | ko_KR / .large | Dark | iPhone 17 | 다크 배경 + 드롭다운 어두운 카드 | withdrawal-dropdown-open-dark.png |
| withdrawal-reason-selected-light | 회원탈퇴 - 사유 선택, 미동의 | step = .input, selectedReason = .rarelyUsed, 동의 미체크 | — | ko_KR / .large | Light | iPhone 17 | 드롭다운 닫힘, 필드에 "자주 사용하지 않아요" 표시, 동의 체크박스 빈 사각, 버튼 여전히 회색 비활성 | withdrawal-reason-selected-light.png |
| withdrawal-reason-selected-dark | 회원탈퇴 - 사유 선택, 미동의 | step = .input, selectedReason = .rarelyUsed, 동의 미체크 | — | ko_KR / .large | Dark | iPhone 17 | 다크 배경 + 선택된 사유 표시 + 비활성 버튼 | withdrawal-reason-selected-dark.png |
| withdrawal-ready-light | 회원탈퇴 - 모든 조건 충족 | step = .input, selectedReason = .rarelyUsed, didAgreeToTerms = true | — | ko_KR / .large | Light | iPhone 17 | 드롭다운 닫힘 + 선택 사유 표시, 동의 체크박스 주황 ✓ 체크됨, "탈퇴하기" 버튼 주황 활성 | withdrawal-ready-light.png |
| withdrawal-ready-dark | 회원탈퇴 - 모든 조건 충족 | step = .input, selectedReason = .rarelyUsed, didAgreeToTerms = true | — | ko_KR / .large | Dark | iPhone 17 | 다크 배경 + 주황 체크박스 + 주황 활성 버튼 | withdrawal-ready-dark.png |
| withdrawal-other-empty-light | 회원탈퇴 - 기타, 텍스트 빈 | step = .input, selectedReason = .other, otherFeedback = "", didAgreeToTerms = true | — | ko_KR / .large | Light | iPhone 17 | "기타" 표시된 드롭다운 닫힘, 텍스트필드 노출(placeholder 표시), 동의 체크됨, 버튼 여전히 회색 비활성 | withdrawal-other-empty-light.png |
| withdrawal-other-filled-light | 회원탈퇴 - 기타, 텍스트 입력됨 | step = .input, selectedReason = .other, otherFeedback = "개선 의견이에요", didAgreeToTerms = true | — | ko_KR / .large | Light | iPhone 17 | 텍스트필드에 입력 텍스트 표시, 동의 체크됨, "탈퇴하기" 버튼 주황 활성 | withdrawal-other-filled-light.png |
| withdrawal-other-filled-dark | 회원탈퇴 - 기타, 텍스트 입력됨 | step = .input, selectedReason = .other, otherFeedback = "개선 의견이에요", didAgreeToTerms = true | — | ko_KR / .large | Dark | iPhone 17 | 다크 배경 + 텍스트 입력 + 주황 활성 버튼 | withdrawal-other-filled-dark.png |
| withdrawal-processing-light | 회원탈퇴 | step = .processing | — | ko_KR / .large | Light | iPhone 17 | 처리 중 로딩 인디케이터, 버튼 비활성 또는 숨김 | withdrawal-processing-light.png |
| withdrawal-a11y | 회원탈퇴 - 사유 미선택 | step = .input, 사유 미선택 | — | ko_KR / .accessibilityExtraLarge | Light | iPhone 17 | 유의사항 안내 텍스트 확대, 드롭다운 라벨 잘림 없음, 체크박스 라벨 줄바꿈 | withdrawal-a11y.png |

## 최소 커버리지 자가 점검

- [x] **상태 4종**: loading / loaded(정상) / empty 없음(해당 없음) / failed — 각 화면별 커버
- [x] **테마 분기**: 없음 (My Profile은 도메인 테마 없음)
- [x] **선택적 필드 분기**: 프로필이미지 nil/있음(2행), 기타 텍스트 비어있음/입력됨(2행), 동의 체크 여부
- [x] **Light/Dark**: 모든 주요 케이스 쌍 분리
- [x] **DynamicType .accessibilityExtraLarge**: 비로그인·계정관리·탈퇴 각 1행 (총 3행)

## 종료 조건 체크

- [x] `<!-- TODO -->` 0개
- [x] 8컬럼(+스냅샷 파일명) 모두 존재
- [x] 각 행에 스냅샷 파일명 결정됨
- [x] 최소 커버리지 5개 항목 통과
