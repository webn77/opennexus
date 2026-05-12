---
name: spec-action
description: /vs·/isok 결정 후 구현 명세(파일별 변경) + TaskCreate 자동 등록 + 테스트 시나리오 생성. 완료 후 /spec-build → /spec-up 파이프라인으로 연결. spec-define 없이 결정된 소규모 변경에 적용.
---

# /spec-action

설계 결정이 확정된 직후, 구현 명세와 Tasks를 만들고 spec-build → spec-up으로 넘긴다.

## 트리거

- `/spec-action` — 현재 컨텍스트에서 결정 자동 추론
- `/spec-action <결정 요약>` — 명시적 지정

## 전체 파이프라인

```
/spec-action          → /spec-build [도메인]  → /spec-up [도메인]
(명세 + Tasks 등록)     (TDD + 구현 + PASS)     (게이트 + 문서 동기화)
```

spec-action은 spec-build의 **전제 파일(plan.md 역할)** 을 대신한다.
spec-build Step 0.5 게이트에서 plan.md 대신 spec-action 산출물을 사용.

---

## 실행 순서

### Step 1. 결정 컨텍스트 수집

현재 대화에서 추출:
- 채택안 (A/B/혼합)
- 변경 파일 목록
- 제약 조건 (이식성, 무변경 파일 등)

명시되지 않은 경우 한 줄 확인 후 진행.

### Step 2. 구현 명세 생성

파일별로 **무엇을 어떻게** 바꾸는지 명시:

```
### [파일 경로]
- 변경 전: <현재 동작>
- 변경 후: <바꿀 내용>
- 핵심 코드 스니펫 (10줄 이내)
```

스니펫은 실제 구현 가능한 수준으로 작성. 추상 설명 금지.

### Step 3. Task 등록

변경 파일 단위로 TaskCreate 실행:
- 파일 1개 = Task 1개 원칙
- subject: "파일명 — 변경 내용 한 줄"
- description: Step 2 해당 명세 내용
- 의존 관계 있으면 addBlockedBy 설정

### Step 4. 테스트 시나리오 생성

3~5개. 형식:

```
| # | 시나리오 | 입력 조건 | 기대 결과 | 확인 방법 |
|---|---|---|---|---|
```

확인 방법은 실행 가능한 명령어로 작성 (bash 한 줄 수준).
→ spec-build가 이 시나리오를 TEST-SPEC.md로 확장.

### Step 5. 명세 파일 저장 + 다음 단계 안내

산출물 저장 경로:
- **slug 파라미터 있을 때** (sprint-exec 배치 실행): `~/.claude/cache/sprint-exec/spec-action-[slug]-latest.md`
- **slug 없을 때** (단독 실행, 기존 동작 유지): `~/.claude/cache/spec-action-latest.md`

산출물을 위 경로에 저장:
```markdown
# spec-action: [결정 제목]
date: YYYY-MM-DD
slug: [kebab-case 작업명]
target_paths: [변경 파일 경로 목록]
mode: hooks/tools | domain

## 구현 명세
[Step 2 내용 — 파일별 변경 전/후 + 스니펫]

## Tasks
[Step 3 등록 Task ID + subject 목록]

## 테스트 시나리오
[Step 4 표]

## 파이프라인 시퀀스
사용자 → /spec-action → spec-action-latest.md 저장
                ↓
         /spec-build (hooks/tools 모드)
           Step 0:  DIAGRAM.md 체크리스트 C1~C8
           Step 0.5: latest.md 존재 확인
           Step 1:  latest.md 읽기 → 구현 대상 추출
           Step 2:  TEST-SPEC.md → ~/.claude/cache/spec-action-tests/[slug]/
           Step 3:  run_tests.sh 생성 + 기준선 실행
           Step 4:  Tasks 재사용 (중복 생성 금지)
           Step 5:  Codex 구현 → FAIL 시 Claude 수정(≤3회)
           Step 6:  전체 PASS 확인
           Step 7:  code-review 자동 실행
                ↓
         /spec-up
           Step 0:  HTML 산출물 있으면 시각 검증 (없으면 스킵)
           Step 1:  run_tests.sh PASS 게이트
           Step 2:  spec 상태 업데이트
           Step 3:  hooks 동기화 (hook-design.md, ~/.claude/CLAUDE.md)
           Step 3-1: AI 접근성 체크
           Step 4:  텔레그램 알림 + latest.md 정리

## 변경 파일 목록
[target_paths 상세]
```

저장 후 출력:
```
## /spec-action 완료

결정: [채택안]
Tasks: [N]개 등록
명세: ~/.claude/cache/spec-action-latest.md

→ /spec-build 실행하세요. (모드: hooks/tools, slug: [slug])
```

---

## 사용 기준

✅ /vs 또는 /isok 직후 — 결정이 확정된 상태
✅ 변경 파일 2~6개 수준
✅ 테스트 가능한 기능 변경

❌ 단순 설정값 변경 1개 (→ 직접 수정)
❌ PRD 수준 신규 기능 (→ /spec-define → /spec-build → /spec-up)
❌ 결정이 아직 확정 안 된 상태 (→ /vs 먼저)
