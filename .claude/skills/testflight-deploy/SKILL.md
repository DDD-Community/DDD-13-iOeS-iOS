---
name: testflight-deploy
description: GitHub Actions "TestFlight Deploy" 워크플로를 올바른 브랜치로, 최근 머지된 티켓들을 요약한 테스트 노트와 함께 실행한다. 사용자가 "테플 빌드 돌려줘", "테스트플라이트 배포해줘", "TestFlight Deploy 실행해줘" 류로 요청할 때 사용.
---

# testflight-deploy

`.github/workflows/testflight.yml`(workflow_dispatch)을 안전하게 트리거하는 스킬이다. 이 워크플로는 실수하기 쉬운 함정이 몇 개 있어서, 매번 처음부터 추론하지 말고 아래 절차를 그대로 따른다.

## 알려진 함정 (반드시 숙지)

1. **`branch` input을 반드시 명시할 것.** 기본값이 `develop`이라, 빠뜨리면 원하지 않는 브랜치가 빌드된다.
2. **`gh run list`/`gh pr view`에 찍히는 `headBranch`/브랜치 라벨은 워크플로 **정의 파일**의 ref일 뿐, 실제 빌드 대상이 아니다.** 실제 checkout된 브랜치를 확실히 확인하려면 `gh run view <id> --log | grep -m1 "ref:"`로 Checkout 스텝 로그를 봐야 한다.
3. **마케팅 버전은 사람이, 빌드 넘버는 자동으로.** TestFlight에 자주 올려도 마케팅 버전(`ProjectEnvironment.marketingVersion`)은 그대로 두고 빌드 넘버만 fastlane이 자동 증가시킨다 — 이 스킬 실행 전에 버전을 손댈 필요 없음(AGENTS.md "버전 관리 & 배포" 섹션 참고).
4. **디스코드 알림은 `jq`로 이스케이프된다(PV-141, 2026-09-12부터).** 멀티라인 테스트 노트를 넣어도 안전하다. 이 스킬은 항상 멀티라인 노트를 만든다.
5. **테스트 노트는 사람이 나중에 다시 만들지 않도록, 이 스킬이 최근 머지 내역에서 자동으로 뽑아 구성한다.**

## 절차

### 1. 대상 브랜치 결정
사용자가 브랜치를 명시하면 그대로 쓴다. 안 정했으면:
- 현재 체크아웃된 로컬 브랜치가 `release/*`면 그걸 기본값으로 제안
- 아니면 사용자에게 물어본다(release 브랜치 이름을 추측해서 멋대로 배포하지 말 것 — 배포는 되돌리기 번거로운 행동이다)

### 2. 테스트 노트 자동 구성
직전 TestFlight 성공 실행 이후 머지된 PR들을 모아 "[TICKET] 제목" 형식으로 줄바꿈해 구성한다.

```bash
# 직전 성공 실행 시각
LAST_RUN_AT=$(gh run list --workflow=testflight.yml --status=success --limit 1 --json createdAt -q '.[0].createdAt')

# 그 이후 대상 브랜치로 머지된 PR (release 브랜치 기준이면 base를 그 브랜치로)
gh pr list --state merged --base <BRANCH> --json number,title,mergedAt \
  --jq ".[] | select(.mergedAt > \"$LAST_RUN_AT\") | .title"
```

각 PR 제목이 이미 `[PV-XXX] ...` 형식이면 그대로 한 줄씩 쓰면 된다(이 저장소 커밋/PR 컨벤션). 결과를 사용자에게 보여주고 확정받은 뒤 진행 — 자동 생성 노트를 검증 없이 그대로 배포하지 않는다.

### 3. 워크플로 실행

```bash
gh workflow run "TestFlight Deploy" \
  -f branch=<BRANCH> \
  -f release_notes="<위에서 만든 멀티라인 노트>"
```

### 4. 실제 대상 브랜치 검증
직후 생성된 run id를 찾아(`gh run list --workflow=testflight.yml --limit 1 --json databaseId -q '.[0].databaseId'`), Checkout 스텝이 의도한 브랜치를 체크아웃했는지 확인한다:

```bash
gh run view <RUN_ID> --log | grep -m1 "ref:"
```

`ref: <BRANCH>`가 아니면 즉시 사용자에게 알리고 중단 — 잘못된 브랜치로 배포가 진행 중이면 취소 여부를 물어본다(`gh run cancel <RUN_ID>`).

### 5. 결과 보고
run URL과 사용된 브랜치·테스트 노트를 사용자에게 요약해서 전달한다. 실행은 15~20분 걸리므로 완료까지 기다리지 말고, 필요하면 나중에 `gh run view <RUN_ID>`로 상태만 다시 확인한다.

## 하지 말 것

- `branch` input 없이 실행(=암묵적으로 develop 배포)
- 테스트 노트 없이 배포(release_notes는 optional이지만, 이 스킬을 쓰는 맥락이면 항상 최근 변경사항을 채워 넣는다)
- 사용자 확인 없이 release/hotfix 브랜치를 추측해서 배포
- 배포 전에 마케팅 버전을 임의로 올리는 것(사람이 결정할 일)
