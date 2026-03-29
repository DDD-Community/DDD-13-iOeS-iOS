# Pickflow

## Git 협업 방식

### Workflow

- `master(main)` - 배포 브랜치
- `develop` - 개발 브랜치
- `feature` - 기능 개발 브랜치 (1인 1피처 가정)

```
master(main) → develop → feature
```

- `master(main)`에서 `develop` 브랜치를 생성합니다.
- `develop`에서 `feature` 브랜치를 생성하여 작업합니다.
- `feature` 작업 완료 시 `develop`으로 PR을 생성합니다.

### Commit Convention

- `[지라 티켓 번호] 자유롭게 작업한 내용 작성`

```
[PICK-12] 로그인 화면 UI 구현
[PICK-35] 네트워크 에러 핸들링 추가
```

### Code Review

- **pn rule** 적용
- PR 본문 및 코멘트는 **영어**로 작성하여 소통
