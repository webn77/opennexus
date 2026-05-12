---
name: spec-build
description: 버전업 구현 단계. TDD → 구현. spec-define(PRD+plan.md) 완료 후 실행.
트리거: /spec-build [도메인]
완료: TEST-SPEC.md + run_tests.sh 생성 + TaskCreate 등록
verified_at: 2026-05-05
실행: 직접+Agent
requires: [ownership-map.md]
---

# /spec-build
> 버전업 구현 단계 — TDD 작성 + 구현 태스크 생성

## 트리거
- `/spec-build [도메인]`
- 예: `/spec-build hire`
- 예: `/spec-build nexus`

**전제 조건:** `/spec-define`으로 spec 완성본 확정 후 실행

> TDD(TEST-SPEC.md + run_tests.sh) 작성은 향후 별도 스킬로 분리 예정. 현재는 spec-build가 TDD + 구현을 모두 담당.

---

## 사람이 해야 하는 것
없음. 구현 태스크 목록 확인 후 구현 진행.
구현 완료 후 `/spec-up [도메인]` 입력.

---

## 자동 실행 순서

### Step 0. 모드 확인 출력

```
모드: [domain | hooks/tools]
```

### Step 0.5. 컨텍스트 감지 + 전제 파일 확인 — 필수 게이트

#### 0.5-A. 컨텍스트 자동 감지

**감지 기준 — 대상 파일 경로 우선:**

1. 변경 대상 파일 중 `~/.claude/` 포함 → **hooks/tools 모드**
2. 변경 대상 파일이 `~/projects/[도메인]/` → **domain 모드**
3. 판단 불가 시 한 줄 확인 후 진행

| 모드 | 감지 조건 | TEST_DIR | plan 파일 |
|---|---|---|---|
| **domain** | 대상 경로가 `~/projects/[도메인]/` | `[도메인]/_pipeline/tests/` | PRD.md + plan.md 필수 |
| **hooks/tools** | 대상 경로가 `~/.claude/` 포함 | `~/.claude/cache/spec-action-tests/<slug>/` | `spec-action-latest.md` |

`<slug>` = 작업 제목 kebab-case (예: `sessions-db-migration`) — 작업별 TEST_DIR 격리.

hooks/tools 모드 감지 시:
```
ℹ️ hooks/tools 모드
   TEST_DIR: ~/.claude/cache/spec-action-tests/<slug>/
   plan: ~/.claude/cache/spec-action-latest.md
```

#### 0.5-B. 전제 파일 확인

**domain 모드:**
⛔ 아래 파일 미존재 시 즉시 중단.
1. 도메인 spec 파일 (hire-v[N]-spec.md 또는 [워크]-spec.md)
2. `[버전]-PRD.md` — spec-define이 생성한 PRD
3. `[버전]-plan.md` — spec-define이 생성한 기술설계

**hooks/tools 모드:**
⛔ 아래 미존재 시 즉시 중단.
1. spec-action 명세 파일 — 아래 순서로 탐색:
   - sprint-exec 배치 실행 시: `~/.claude/cache/sprint-exec/spec-action-[slug]-latest.md`
   - 단독 실행 시: `~/.claude/cache/spec-action-latest.md`
   - slug는 환경변수 `SPRINT_EXEC_SLUG` 또는 호출 컨텍스트에서 추출

**hooks/tools 모드 contracts 검증:**
latest.md 존재 확인 후 `~/.claude/skills/contracts/spec-action.output.schema.md` 기준으로 필드 검증:

- date / slug / mode / 구현명세 / Tasks 섹션 존재 확인
- 검증 실패 → "⛔ spec-action 출력 형식 불일치. /spec-action 재실행하세요." 출력 후 중단

누락 시:
```
⛔ spec-build 중단
domain 모드 → 누락: [파일명] → /spec-define [도메인] [버전] 먼저 실행하세요.
hooks/tools 모드 → spec-action-latest.md 없음 → /spec-action 먼저 실행하세요.
```

**spec-hardening을 실행한 경우 추가 확인 (domain 모드만):**
4. `[버전]-ownership-map.md` — 병렬 에이전트 분배 기준 (없으면 순차 실행으로 폴백)

ownership-map 없을 때:
```
⚠️ ownership-map 없음 — 순차 실행으로 진행합니다.
   병렬 실행을 원하면 먼저 /spec-hardening [도메인] [버전] 실행하세요.
```

### Step 1. 구현 대상 읽기

**domain 모드:**
- 도메인 spec 파일에서 🆕 변경 항목 파악
- 구현 대상 목록 추출
- ownership-map 존재 시: 에이전트별 담당 태스크 분류

**hooks/tools 모드:**
- `~/.claude/cache/spec-action-latest.md` 읽기
- `## 구현 명세` 섹션에서 변경 파일·내용 추출
- `## Tasks` 섹션에서 기존 Task 목록 확인 → Step 4에서 재사용

### Step 2. TEST-SPEC.md 작성

**domain 모드:** `[도메인]/_pipeline/tests/TEST-SPEC.md` 생성
**hooks/tools 모드:** `~/.claude/cache/spec-action-tests/<slug>/TEST-SPEC.md` 생성
(`<slug>`는 spec-action-latest.md의 slug 필드 사용)
- 변경 항목 기반 검증 대상 도출
- 각 테스트케이스: 입력 / 기대 출력 / PASS 조건 명시

**[필수] 텍스트 처리 코드 감지 시 — 인코딩 경계 케이스 자동 추가**
구현 대상에 문자열 슬라이싱·파이프(`head`, `cut`, `tr`, `sed`, `awk` 등)가 있으면:
- Happy path: ASCII 짧은 입력
- 경계값: CJK(한국어) 50바이트 초과 입력 (멀티바이트 경계 잘림 재현)
- 빈 입력 / 특수문자 포함 입력

**[필수] 부수 효과(side effect) 있는 코드 — 결과물 확인 커맨드 명시**
파일 쓰기·DB·API·텔레그램 전송 등 부수 효과가 있으면:
- exit code 확인만으로 PASS 금지
- 실제 결과물(파일 내용·레코드·응답) 존재 여부를 확인하는 커맨드를 PASS 조건에 포함

### Step 3. run_tests.sh 작성 + 초기 실행

**domain 모드:** `[도메인]/_pipeline/tests/run_tests.sh` 생성
**hooks/tools 모드:** `~/.claude/cache/spec-action-tests/<slug>/run_tests.sh` 생성

- TEST-SPEC.md 기반 shell assert 구현 (mock 사용)
- `bash run_tests.sh` 실행 → 구현 전 기준선 확인 (일부 FAIL 정상)

### Step 4. 구현 태스크 확정

**domain 모드:**
- spec 🆕 항목 기반으로 TaskCreate 등록 + 의존성 설정

**hooks/tools 모드:**
- spec-action-latest.md의 `## Tasks` 섹션 Tasks 재사용 (중복 생성 금지)
- TaskList로 기존 pending Tasks 확인 → 그대로 사용
- 추가 Task 필요 시에만 TaskCreate

### Step 4.5. IMPLEMENTATION.md 작성

컨텍스트 오염 방지를 위해 구현 명세를 파일로 먼저 작성 후 경로만 전달한다.

**파일 경로:** `~/.claude/cache/spec-build-<slug>/IMPLEMENTATION.md`

```markdown
# IMPLEMENTATION.md — <slug>
## 변경 파일 목록
- [파일1]: [변경 내용 1줄]
- [파일2]: [변경 내용 1줄]

## 스텝별 명세
### Step 1. [파일1] 수정
변경 내용: ...
완료 조건: ...

### Step 2. [파일2] 생성
...
```

### Step 5. 구현 실행 (Claude 직접)

ownership-map 기반 태스크를 Claude가 직접 구현한다.
IMPLEMENTATION.md를 읽고 명세대로 파일을 수정/생성한다.

**테스트 실패 수정 루프 (태스크당 최대 3회):**
```
구현 완료
    ↓
bash run_tests.sh
    ├── PASS → 다음 태스크
    └── FAIL → FAIL 원인 분석 + 직접 수정
                    ↓
              bash run_tests.sh 재실행
                    ├── PASS → 다음 태스크
                    └── FAIL → 재시도 (최대 3회)
                                    ↓ (3회 초과)
                              사용자 보고 후 중단
                              "⛔ [태스크명] 3회 수정 실패. 수동 개입 필요."
```

### Step 6. 전체 PASS 확인
- 모든 태스크 완료 + run_tests.sh 전체 PASS

### Step 7. 코드 리뷰 (인라인)

구현된 파일 대상으로 3관점 직접 검토:

1. **보안** — 인증·인가 누락 / 입력 검증 없음 / 민감정보 노출 / SQL 인젝션·XSS
2. **성능** — 불필요한 I/O·루프·잠금 / N+1 / 타임아웃 없는 외부 호출
3. **유지보수** — 가독성 / 단일책임 위반 / 중복 / 50줄 초과 함수

### Step 7.5. 컨벤션 체크 (인라인)

체크 항목:
- 네이밍 규칙 (snake_case·camelCase·PascalCase 일관성)
- 폴더 구조 (도메인 CLAUDE.md 기준 준수)
- 함수 분리 (단일 책임·50줄 초과·중첩 depth)
- 타입 일관성 (타입 힌트·any 금지)

출력:
```
### 코드 리뷰 + 컨벤션 체크
보안: ✅ / ❌ [위반 항목]
성능: ✅ / ⚠️ [권고 항목]
유지보수: ✅ / ⚠️ [권고 항목]
네이밍: ✅ / ⚠️ [위반 항목]
폴더구조: ✅ / ❌ [위반 항목]
함수분리: ✅ / ⚠️ [권고 항목]
타입일관성: ✅ / ❌ [위반 항목]
판정: PASS / WARN / FAIL
```

- Step 7 + 7.5 모두 PASS → `/spec-up [도메인]` 실행 **(필수 게이트 — 생략 불가)**
- 지적 사항 있음 → 수정 후 run_tests.sh 재실행 → Step 7 재실행

---

## 완료 후 출력

```
## /spec-build [도메인] 완료

### TDD
TEST-SPEC.md: [경로] — N개 테스트케이스
run_tests.sh: N/N PASS ✅

### 구현 완료
#1 ✅ ...
#2 ✅ ...
...

### 최종 테스트
N/N PASS ✅

---
⛔ 다음 단계 필수 — 생략 불가
→ /spec-up [도메인]
```
