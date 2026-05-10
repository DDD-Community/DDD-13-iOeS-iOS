# [KAN-76] 로그인 화면 UI 테스트 케이스

> **Phase B 산출물 (Gate 2)**. Phase A(ViewModel TDD)가 완료된 후에 채운다.
> 작성 가이드: `docs/phases/phase-b-ui-cases.md` (8컬럼 정의 + 최소 커버리지 규칙).
>
> 이 표가 채워지기 전엔 Phase C(swift-snapshot-testing) 진입 금지.

## 매트릭스

| # | 케이스 | ViewModel 상태 | 입력/이벤트 | 기대 UI | 스냅샷 파일명 | iPad/Dynamic Type | 비고 |
|---|---|---|---|---|---|---|---|
| <!-- TODO: Phase B 진입 시 채움 --> | | | | | | | |

## 최소 커버리지 (Phase B 진입 시 본 표를 8컬럼으로 확장)

- [ ] 기본 렌더 (idle, isLoading=false, errorMessage=nil)
- [ ] 카카오 로딩 (isLoading=true, 카카오 버튼만 spinner)
- [ ] 애플 로딩 (isLoading=true, 애플 버튼만 spinner) <!-- 또는 단일 isLoading 공유 시 그에 맞춰 케이스 정의 -->
- [ ] 에러 alert 표출 (errorMessage="로그인에 실패했어요")
- [ ] (선택) iPad 사이즈
- [ ] (선택) Dynamic Type XL/XXL

## 디바이스/환경 고정값 가이드

- 기본: iPhone 15 Pro, iOS 17, dark color scheme (강제), Pretendard 폰트 등록 후
- locale: `ko_KR`
- 비교 정밀도: `precision: 0.99`, `perceptualPrecision: 0.98` (KAN-51 선례 따름)

> 본 매트릭스가 채워지면 §10 Phase C 진입.
