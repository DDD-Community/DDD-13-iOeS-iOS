# [KAN-76] Login Discussion

## Decisions Applied In This Branch

| Topic | Applied Decision | Follow-up |
|---|---|---|
| Apple endpoint | `POST /auth/apple` | Confirm with backend before merge if API contract changed. |
| Apple request body | `{ "identity_token": "<JWT>", "nonce": "<raw>" }` | Confirm snake_case key naming with backend. |
| Nonce handling | iOS sends raw nonce to backend, Apple request receives `SHA256(rawNonce)` | Confirm backend expects raw nonce, not hashed nonce. |
| Response model | `AppleSignInResponse` mirrors `KakaoSignInResponse` | Consider `SocialSignInResponse` refactor outside KAN-76. |
| Guest entry | `continueAsGuestTapped()` sets `didRequestGuestEntry` only | Routing/session behavior remains follow-up scope. |
| Logo asset fallback | `ic_flare` is used when present, SF Symbol fallback remains until asset lands | Replace fallback when Figma-exported vector assets are added. |

## Remaining Product/API Questions

1. Should guest mode route to exploration without a token, or should backend issue a guest token?
2. Should Kakao/Apple sign-in responses be unified into one DTO before more providers are added?
3. Are `ic_flare`, `ic_apple`, and `pickflow_wordmark` assets expected from design export, or should existing app assets remain the source of truth?
