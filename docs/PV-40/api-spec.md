# PV-40 서버 API 스펙 정리 (2026.08.14 / 브랜치 `2026/HJY/유저스팟_공개시스템_개발`)

출처: `user-spot-publication-system (1).html` (Redoc) → 원본 OpenAPI는 `docs/PV-40/openapi.json`으로 추출해둠.
서버 기준 문서: `docs/user-spot-publication-system.md` (서버 레포)

## 공통
- 모든 응답은 `ApiResponse<T>` 래퍼 (`success`, `code`, `message`, `data`) — 앱의 `APIEnvelope<T>`와 동일
- 인증 없음/무효 → `401 C004`, 권한 없음 → `403 C005`
- **비공개 스팟 접근은 403이 아니라 `404 SP001`** (존재 여부 자체를 숨김)

## 상태값 (서버 enum)
`DRAFT`(나만보기) → `PENDING`(검수중) → `PUBLISHED`(승인/공개) / `REJECTED`(반려)
반려 후 재신청 → `RE_REVIEW_PENDING`(재검토대기)

기획 용어 매핑: 나만보기=DRAFT, 검수중=PENDING·RE_REVIEW_PENDING, 오픈=PUBLISHED, 반려=REJECTED, 추천=like

## 엔드포인트

| 구분 | Method | Path | 비고 |
| --- | --- | --- | --- |
| 나만의 스팟 수정 | PUT | `/v1/users/me/my-spots/{spotId}` | multipart. DRAFT/REJECTED만 가능 |
| 나만의 스팟 삭제 | DELETE | `/v1/users/me/my-spots/{spotId}` | 논리삭제. PENDING/RE_REVIEW_PENDING이면 409 |
| 공개 해제 (철회/비공개 전환) | DELETE | `/v1/users/me/my-spots/{spotId}/publications` | 철회·비공개 전환 **동일 엔드포인트** |
| 오픈 신청 | POST | `/v1/users/me/my-spots/{spotId}/open-requests` | DRAFT→PENDING, REJECTED→RE_REVIEW_PENDING |
| 좋아요(추천) 등록 | POST | `/v1/spots/{spotId}/likes` | **201** 성공 |
| 좋아요(추천) 취소 | DELETE | `/v1/spots/{spotId}/likes` | 200 |
| 스팟 상세 | GET | `/v1/spots/{spotId}` | 필드 추가 (아래) |
| 스팟 미리보기 | GET | `/v1/spots/{spotId}/preview` | 필드 추가 |
| 스팟 리스트 | GET | `/v1/spots` | 추천순 정렬 기준 변경 |
| 저장된 스팟 | GET | `/v1/users/me/saved-spots` | `isPrivate` 추가, 비공개 포함 |
| (어드민) 검수 | POST | `/v1/admin/spots/{spotId}/reviews` | iOS 범위 밖 |

### 요청/응답 요점
- **수정** `UpdateMySpotRequest` (multipart `request` + 선택 `image`)
  - required: `name`(≤100), `theme`, `latitude`, `longitude` / optional: `comment`, `recordedDate`(yyyy-MM-dd), `recordedTime`(HH:mm)
  - **전달값으로 전체 덮어쓰기**. image 미첨부 시 기존 이미지 유지. 수정으로 상태는 안 바뀜
  - 좌표 변경 시 주소·기상격자·혼잡·날씨 재계산
  - 응답: `{ spotId, status, imageUrl }`
- **공개 해제** 응답: `{ spotId, previousStatus, status(항상 DRAFT) }` → `previousStatus`로 "철회"인지 "비공개 전환"인지 구분해 토스트 문구 분기
- **오픈 신청** 응답: `{ spotId, status }` (PENDING 또는 RE_REVIEW_PENDING)
- **좋아요** 응답: `{ likeCount, isLiked }` — 서버 최종 반영값이므로 낙관적 업데이트 후 이 값으로 재동기화
- **상세 신규 필드**: `status`, `isCurated`, `likeCount`, `isLiked`, `isLikeable`, `rejection`
  - `rejection`: `{ reason, reasonLabel, guideMessage, detail, rejectedAt }` — 반려된 **내** 스팟일 때만, 타인에겐 미노출
  - `reason` enum: `DUPLICATE`, `LOW_QUALITY`, `LOCATION_MISMATCH`, `FILTER_MISMATCH`, `ETC`
  - `isLikeable`: 비공개 상태의 유저 스팟이면 false → 추천 버튼 노출 조건으로 그대로 사용 가능
- **미리보기 신규 필드**: `isCurated`, `likeCount`, `isLiked`, `isLikeable`
- **리스트**: 정렬 `RECOMMENDED`(기본)가 `bookmark_count` → **`like_count` 기준으로 변경**, 동률은 북마크 수. `likeCount`/`isLiked` 추가. 페이지 6개 단위
- **저장된 스팟**: 비공개 스팟 제외 필터 제거 → 비공개도 내려옴. `isPrivate` 추가. **비공개면 `imageUrl`이 null로 마스킹**. 보관함 카드 지표는 `bookmarkCount` 대신 `likeCount` 로 내려받아 "추천 N" 으로 표시

### 에러 코드
| 코드 | HTTP | 의미 | 클라 처리 |
| --- | --- | --- | --- |
| C004 | 401 | 인증 필요 | 로그인 유도 (비로그인 추천 시도) |
| C005 | 403 | 권한 없음 | - |
| SP001 | 404 | 없거나 비공개 | "삭제되었거나 볼 수 없는 스팟" |
| SP004 | 409 | 이미 처리된 신청 (검수 확정 경합) | **"이미 처리된 신청이에요" + 최신 상태로 화면 갱신** |
| SP005 | 400 | 오픈 신청 불가 상태 | - |
| SP008 | 403 | 본인 스팟 아님 | - |
| SP009 | 400 | 해제할 대상 없음 (이미 DRAFT) | - |
| SP010 | 400 | 수정 불가 상태 (검수중/공개중) | "공개를 먼저 해제해주세요" |
| SP011 | 409 | 검수 중이라 삭제 불가 | "오픈 신청을 먼저 철회해주세요" |
| SL001 | 409 | 이미 좋아요함 | 상태 재동기화 |
| SL002 | 400 | 좋아요 안 한 스팟 | 상태 재동기화 |
| SL003 | 400 | 좋아요 불가 상태 | - |

## 클라이언트 작업 항목

### 즉시 깨지는 것 (호환성 — 최우선)
1. **`SpotTheme` 디코딩 실패** — `Pickflow/Sources/Core/Services/Models/Spot.swift`
   앱은 `SUNSET`/`YUNSEUL`만 알고, 알 수 없는 코드는 `throw`. 서버에 `SUNLIGHT`(SL)·`NIGHT_VIEW`(NV)가 신규 추가됨 → 해당 테마 스팟이 하나라도 내려오면 리스트/상세/뷰포트 응답 전체 디코딩 실패.
2. **`MySpotStatus` 디코딩 실패** — `Models/MySpotListItem.swift`
   앱은 `PENDING`/`PUBLISHED`/`REJECTED`만. 신규 `DRAFT`·`RE_REVIEW_PENDING`이 내려오면 내 스팟 목록 전체 실패.
   → 두 enum 모두 unknown 케이스 허용(또는 항목 단위 skip)으로 먼저 바꿔둬야 함.

### 신규/변경
3. `SpotDetail`에 `status`/`isCurated`/`likeCount`/`isLiked`/`isLikeable`/`rejection` 추가
4. `SpotPreviewResponse`에 `isCurated`/`likeCount`/`isLiked`/`isLikeable` 추가
5. `SpotListItem`에 `likeCount`/`isLiked` 추가, `SpotListSort.recommended.displayName` "북마크 순" → 좋아요/추천 기준 문구로 변경
6. `SavedSpotItem`에 `likeCount`/`isPrivate` 추가 + `imageUrl` null 대응(비공개 플레이스홀더), `deleted`(삭제됨)와 `isPrivate`(비공개 전환됨) UI 분리
7. 신규 엔드포인트 4종 추가 (수정 PUT multipart / 삭제 DELETE / 공개해제 DELETE publications / 오픈신청 POST open-requests) + 좋아요 2종
8. 에러코드 → 사용자 문구 매핑 (위 표). 현재 `APIErrorHandler`는 전역 alert 하나뿐이라, PV-40은 토스트/인라인 처리라서 호출부에서 `APIError.code`로 분기 필요

## 기획 대비 미해결 — 서버 확인 필요

1. **출처 표기 문자열이 없음**
   기획 3.7은 큐레이션 스팟에 "한국관광공사" / "Pickflow 운영자" 등 **소스별 고정값** 노출을 요구하는데, API에는 `isCurated: Bool`만 있음. 출처명을 내려주는 필드가 필요하거나, 앱에서 고정 문구 하나로 처리할지 결정 필요.
2. **검수 결과 알림 근거 데이터가 없음**
   기획 3.4의 스낵바 / 저장 탭 인디케이터("결과 확인 전까지 유지") / 상세 첫 진입 "스팟 오픈 완료" 모달은 **"결과를 아직 확인 안 했다"는 서버 플래그나 알림 API**가 있어야 정확한데, 이번 스펙엔 없음. 지금 스펙만으론 앱이 로컬에 이전 status를 저장해두고 비교하는 방식뿐 → 기기 변경·재설치 시 유실, 인디케이터 해제 시점도 로컬 판단. 서버에 알림/미확인 플래그 추가 여부 협의 필요.
3. **지도(뷰포트) API가 이번 문서에 없음**
   앱은 `/v1/spots/viewport`를 쓰는데(`SpotViewportEndpoint`) 문서에 미포함. 응답 `SpotSummary`는 `isMySpot`만 있고 `isCurated`가 없음 → 기획 In Scope의 "지도 핀 색상으로 큐레이션 vs 유저오픈 구분"을 지금 데이터로는 못 함. 또한 승인된 타인 유저 스팟이 뷰포트 응답에 포함되는지, 내 DRAFT/PENDING 스팟이 어떻게 내려오는지(검수중은 지도에 안 떠야 함) 확인 필요.
   ※ 참고: 기획 In Scope의 "핀 색상 구분"과 3.7 표의 "기본 상태는 일반 스팟과 동일한 형태"가 서로 어긋남 — 기획도 확인 필요.
4. **내 스팟 목록 `GET /v1/users/me/my-spots`도 문서에 없음**
   상태별 표시(검수중/반려 뱃지)와 반려 사유 진입점이 이 목록에 필요한데, 신규 상태값(DRAFT/RE_REVIEW_PENDING)과 반려 정보가 이 응답에 포함되는지 확인 필요.
5. **재신청 폼 프리필 소스**
   기획은 사진/스팟명/주소/필터/코멘트 프리필을 요구. 상세 조회로 대부분 채워지지만, 주소는 수정 요청 스키마에 없고 좌표로 서버가 재계산하는 구조 → 폼에서 주소는 표시용, 실제 전송은 좌표 기준임을 확인.
6. **좋아요 연타 방지**: 서버는 `SL001`/`SL002`로 응답. 클라에서 in-flight 중복 요청 차단 + 응답의 `likeCount`로 재동기화하는 방식으로 처리.
