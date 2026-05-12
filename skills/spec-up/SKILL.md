---
name: spec-up
description: 버전업 완료 게이트. 테스트 PASS 확인 후 spec 최종 업데이트.
트리거: /spec-up [도메인]
완료: SPEC.md 업데이트 + history.jsonl 완료 기록
verified_at: 2026-05-05
실행: 직접
requires: [TEST-SPEC.md, run_tests.sh]
---

# /spec-up
> 버전업 완료 게이트 — 테스트 PASS 확인 후 spec 최종 업데이트

## 트리거
- `/spec-up [도메인]`
- 예: `/spec-up hire`
- 예: `/spec-up nexus`

---

## 사람이 해야 하는 것
딱 하나: **`/spec-up [도메인]` 명령어 입력**

테스트 PASS면 나머지 전부 자동. FAIL이면 차단.

---

## 자동 실행 순서

### Step 0. 시각 검증 (HTML 산출물이 있는 경우만)

HTML 파일을 생성·수정한 경우에만 실행. 없으면 스킵.

브라우저 또는 VS Code preview로 확인:
- 레이아웃 구조가 의도한 대로인지 눈으로 확인
- spec에 체크리스트가 정의된 경우 → 항목별 PASS/FAIL 판단:
  ```
  ### 시각 검증 결과
  □ 01. [체크리스트 항목] — PASS / FAIL
  전체 PASS → Step 1 진행
  FAIL → 해당 파일 수정 후 재확인
  ```
- HTML 산출물 없음 → 이 단계 스킵, Step 1 자동 진행

## 코드리뷰 게이트 (spec-build Step 7 자동 실행)

| 관점 | 체크 항목 |
|------|-----------|
| 보안 | 인증·인가 누락, 입력 검증, 민감정보 노출, SQL 인젝션, XSS |
| 성능 | 불필요한 I/O·루프·잠금, N+1 쿼리, 타임아웃 없는 외부 호출 |
| 유지보수 | 가독성, 단일책임 위반, 중복 코드, 50줄 초과 함수 |

판정: **PASS / WARN / FAIL**
- WARN: 권고 사항, 진행 가능
- FAIL: 수정 후 재실행 필수

### spec-up 6개 체크리스트 (생략 불가)

```
[ ] run_tests.sh 전체 PASS
[ ] 코드리뷰 PASS 또는 WARN (FAIL 없음)
[ ] 컨벤션 체크 PASS 또는 WARN
[ ] spec 파일 업데이트 (변경 내용 반영)
[ ] hooks 동기화 (hook-design.md, CLAUDE.md)
[ ] 텔레그램 완료 알림
```

---

### Step 1. 테스트 실행 (게이트)

**domain 모드:**
```bash
bash [도메인]/_pipeline/tests/run_tests.sh
```
FAIL → `[도메인]/_pipeline/tests/FAIL-LOG.md` 저장 + 중단

**hooks/tools 모드:**
```bash
# slug는 spec-action-latest.md의 slug 필드
bash ~/.claude/cache/spec-action-tests/<slug>/run_tests.sh
```
FAIL → `~/.claude/cache/spec-action-tests/<slug>/FAIL-LOG.md` 저장 + 중단

- **FAIL** → "테스트 미통과. 실패 항목 수정 후 재실행." 출력 + 중단
- **PASS** → Step 2 진행

### Step 2. spec 최종 업데이트

**domain 모드:**
- `status: 설계 확정` → `status: 구현 완료`
- `updated` 날짜 갱신
- 구현 중 변경된 함수명·파일경로·스키마 반영
- 🆕 표시 제거 (확정된 내용이므로)
- 구현 현황 테이블 갱신 (에이전트 상태, 경로 등)

**hooks/tools 모드:**
- spec 파일 없음 — 이 단계 스킵
- `~/.claude/cache/spec-action-latest.md` 삭제는 Step 3에서 처리

### Step 3. 관련 문서 동기화

**domain 모드:**
- `[도메인]/CLAUDE.md` — 버전 번호 + 날짜 갱신, 변경된 슬래시 명령·원칙 반영
- `[도메인]-design.md` — `status: 설계 확정 / 구현 대기` → `status: 구현 완료`
- `[도메인]/agents/PATTERNS.md` — 에이전트 상태(⬜→✅) 동기화
- `guides/pipeline.md` — 단계별 가이드 v6.0 기준으로 업데이트
- 기타 spec에서 참조된 문서 중 내용이 달라진 것

**hooks/tools 모드:**
- `~/.claude/guides/hook-design.md` — Hook Registry 변경 사항 반영
- `~/.claude/CLAUDE.md` — 변경된 훅·스킬·경로 최신화
- `~/.claude/cache/spec-action-latest.md` 삭제 (완료 후 정리)
- 기타 변경된 훅·스킬 SKILL.md에서 참조하는 문서

### Step 3-1. AI 접근성 체크 (필수)
⛔ **이 단계 누락 시 다음 세션 AI가 시스템을 모름**

**domain 모드:**
`~/projects/[도메인]/CLAUDE.md` 또는 `~/projects/CLAUDE.md`에 해당 시스템이 등록되어 있는지 확인:
- 신규 시스템이면 `## 운영 중인 시스템` 테이블에 추가
- 기존 시스템이면 경로·스킬명 최신화 여부 확인

**hooks/tools 모드:**
`~/.claude/CLAUDE.md` 또는 `~/.claude/guides/hook-design.md`에 변경된 훅·DB·파일 경로가 반영되어 있는지 확인:
- 신규 DB/파일 → 경로 등록
- 기존 경로 변경 → 최신화

출력:
```
### AI 접근성 체크
✅ [CLAUDE.md 또는 hook-design.md 경로] — [변경 내용] 등록 확인
```

### Step 4. 완료 알림
- 텔레그램: "[도메인] v[N] 구현 완료. spec + 관련 문서 업데이트됨."
- 태스크 #spec-up completed 처리

---

## FAIL 시 출력 형식

```
❌ 테스트 미통과 — spec 업데이트 차단

실패 항목:
  - T3: 텔레그램 승인 파싱 > ㅇㅋ → APPROVED
  - T5: REWRITE 카운터 > count=2 → 재집필 차단

수정 후 /spec-up hire 재실행하세요.
```

---

## PASS 시 출력 형식

```
✅ 41/41 PASS — spec 업데이트 완료

### spec 업데이트
변경 파일: $NEXUS_VAULT/03_Projects/hire/hire-v6-spec.md
  - status: 구현 완료
  - updated: 2026-04-19

### 관련 문서 동기화
✅ hire/CLAUDE.md — v6.0 확인
✅ hire-v6-design.md — status: 구현 완료
✅ agents/PATTERNS.md — 전체 ✅ 상태 확인
✅ guides/pipeline.md — v6.0 반영

텔레그램 전송 완료.
```

---

## 전체 버전업 흐름 요약

```
사람: /spec-define hire v7.0
      "승인 게이트를 텔레그램 버튼으로 바꾸고 싶어"

Claude: 갭분석 → 태스크 생성 → TDD → 구현 자동 진행

사람: ok  ← STEP 승인 (터미널이면 채팅, 텔레그램이면 메시지)

Claude: 다음 STEP 자동 진행

사람: /spec-up hire  ← 마지막에 한 번

Claude: run_tests.sh 실행 → PASS → spec 업데이트 완료
```

**사람이 하는 것: 변경 내용 말하기 + 중간 ok/no + /spec-up**
