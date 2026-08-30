# Pickflow

## Git 협업 방식

### Workflow

- `develop` - trunk. 모든 기능이 여기로 모입니다.
- `feature/*` - 기능 개발 브랜치 (1인 1피처 가정)
- `release/x.y.z` - 배포용 브랜치. **Create Release** 워크플로가 버전 상향과 함께 생성합니다.
- `main` - 현재 출시본을 가리키는 포인터. 핫픽스는 여기서 갈라집니다.
- `hotfix/*` - 출시본 긴급 수정 브랜치

```
feature → develop → release/x.y.z → 배포 + 태그 → main 전진 → develop 백머지
hotfix  → main → 배포 + 태그 → develop 백머지
```

- `develop`에서 `feature` 브랜치를 생성하여 작업합니다.
- `feature` 작업 완료 시 `develop`으로 PR을 생성합니다.
- 배포할 때가 되면 Actions → **Create Release** 로 릴리즈 브랜치를 만듭니다.
- QA 중 나온 수정은 `release/x.y.z`로 PR 하고, 배포·태깅 후 `develop`으로 백머지합니다.
- 출시 중인 버전에 급한 수정이 필요하면 `main`에서 `hotfix/*`를 따서 `main`으로 PR 합니다.
- 배포·태깅 후 `main`을 그 태그로 전진시킵니다. 이 단계를 빠뜨리면 핫픽스가 옛 버전에서 갈라집니다.

자세한 버전·배포 규칙은 [AGENTS.md](AGENTS.md)를 참고하세요.

### Commit Convention

- `[지라 티켓 번호] 자유롭게 작업한 내용 작성`

```
[PICK-12] 로그인 화면 UI 구현
[PICK-35] 네트워크 에러 핸들링 추가
```

### Code Review

- **pn rule** 적용
- PR 본문 및 코멘트는 **영어**로 작성하여 소통
