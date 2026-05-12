---
name: save
description: 세션 종료 전 컨텍스트 저장 + 다음 세션 인계. 글로벌 PO 전용. Trigger when user says /save, /handoff, 저장, 저장해줘, 세션 종료, 마무리할게, 작업 끝, 오늘 끝, 종료할게. Telegram only: trigger when user says "exit" as a standalone message (not in code discussion context). /save-restart also triggers this skill with restart flag. DO NOT trigger when "save" or "exit" appears in code/programming context (e.g., "save the file", "save this variable", "save to DB", exit() function).
트리거: /save, 저장, 마무리할게, 작업 끝, 오늘 끝, 종료할게, /save-restart, 저장하고 재시작
완료: ~/.nexus8/checkpoint.json 갱신 + 데몬 백그라운드 실행 (snapshot, history.jsonl, git push, sessions.db)
실행: 직접
---

# Save Skill (글로벌 PO 전용)
# v1.0 | 2026-05-02 | /handoff 대체 신규 구현

세션 작업 내용을 checkpoint.json에 저장하고 백그라운드 데몬으로 나머지 처리.
`/save` = 저장만 / `/save-restart` = 저장 + bot-restart.sh 호출

---

## Step 0.8. 종료 전 완결성 검증

체크 항목 (해당 없으면 스킵):
```
□ 요청받은 작업이 완료됐는가?
  → 외부 dependency·사용자 확인 필요 미완료 → checkpoint.json blocked[]
□ 파일 저장 위치가 올바른가?
  → obsidian vs projects 혼용 오류 여부
□ 범위 밖 파일을 수정했는가?
  → 있으면 checkpoint.json todo[]에 기록
□ 연관 파일 누락이 있는가?
  → PRD 수정 → 설계노트 업데이트 여부
  → 스킬 신설 → MEMORY.md 등록 여부
  → 스크립트 경로 변경 → CLAUDE.md 반영 여부
  → 누락 발견 시 → 지금 즉시 처리 OR checkpoint.json todo[]에 기록
□ 다음 세션이 이 상태에서 바로 시작 가능한가?
  → No면 checkpoint.json next에 선행 조건 명시
```

**blocked[] vs todo[] 구분**:
- `blocked`: 외부 요인으로 진행 불가 (사용자 확인, 외부 시스템 의존)
- `todo`: 이번 세션에서 하지 못한 연관 작업 (다음 세션 시작 즉시 처리)

---

## Step 1. 이전 checkpoint.json 백업 (히스토리 diff 기준점)

데몬이 이전 todo[]와 비교할 수 있도록 .prev 저장:

```bash
cp ~/.nexus8/checkpoint.json ~/.nexus8/checkpoint.json.prev 2>/dev/null || true
```

---

## Step 2. checkpoint.json 갱신

`~/.nexus8/checkpoint.json` 을 생성/갱신한다.

```json
{
  "when": "<ISO8601 현재 시각>",
  "domains": {
    "work": "<현재 상태 1줄>",
    "hire": "<현재 상태 1줄>",
    "study": "<현재 상태 1줄>",
    "analyze": "<현재 상태 1줄>"
  },
  "next": "<다음 세션 첫 번째 액션 — 1문장, 구체적으로>",
  "blocked": ["<외부 dependency·사용자 확인 필요 항목>"],
  "todo": ["<이번 세션 미완료 연관 작업>"]
}
```

**작성 원칙:**
- `next` placeholder 금지 — "B-v7-11 Circuit Breaker 구현" O / "계속 진행" X
- 총 2000자 캡 — 넘으면 todo[] 오래된 것 정리 후 저장
- 도메인에 변경 없으면 기존 값 유지

**todo[] 항목 삭제 시 status_overrides 처리:**
이번 세션에서 실패/중단된 항목이 있으면 checkpoint.json에 임시 필드 추가:
```json
"_status_overrides": {
  "<todo 항목 원문>": "dropped"
}
```
데몬이 읽고 처리 후 삭제. 명시 없는 삭제 항목은 기본 `done` 처리.

---

## Step 3. 메모리 + 스킬 리뷰

### A. 기존 메모리 활용 검증
이번 세션에서 기존 메모리 참조로 행동이 실제로 달라진 게 있었나?
- 있으면 → 해당 메모리 파일 하단 `last_verified: YYYY-MM-DD` 갱신
- 없으면 → 스킵

**만료 메모리 체크:**
save 실행 시 `expires_at` 필드가 today 이전인 파일 탐지 → 삭제 후보 목록 출력 → 사용자 확인 후 삭제.

### B. 신규 메모리 후보
선호/거부 표현, 다음 세션도 기억할 결정/제약/교훈 있었나?

**저장 경로 — 2단계 승격제:**

1. **신규 후보** → `~/.claude/projects/memory/candidates/` 에 저장
   - frontmatter에 `count: 1` 필드 추가
   - 저장 전 `memory/`와 `memory/candidates/` 파일명으로 중복 확인 — 이미 존재하면 count +1만
   - **즉시 승격 예외** (candidates/ 거치지 않음): 명시적 사용자 지시, 보안·운영 제약, 장기 프로젝트 사실

2. **승격 조건** — 매 save마다 candidates/ 파일 전체 확인:
   - `count >= 3` 인 파일 → `memory/` 로 이동 + MEMORY.md 인덱스 등록
   - count는 **서로 다른 세션에서 관찰된 횟수** 기준

**승격 체크 (candidates/ 파일이 있을 때만):**
```bash
CAND_DIR="$HOME/.claude/projects/memory/candidates"
find "$CAND_DIR" -maxdepth 1 -type f -name '*.md' -print0 2>/dev/null |
while IFS= read -r -d '' f; do
  count=$(awk '
    NR==1 && $0=="---" { fm=1; next }
    fm && $0=="---" { exit }
    fm && $1=="count:" && $2 ~ /^[0-9]+$/ { print $2; exit }
  ' "$f")
  count=${count:-0}
  [ "$count" -ge 3 ] && echo "승격 대상: $f (count=$count)"
done
```
승격 대상이 나오면: 파일 `memory/` 로 이동 → MEMORY.md 한 줄 추가 → candidates/ 원본 삭제.

**candidates/ 폐기 (매 save 확인):**
```bash
find "$CAND_DIR" -maxdepth 1 -name '*.md' -mtime +30 -print
```
30일 이상 count 1 상태인 파일 → 조용히 삭제.

### C. 스킬 후보
3회 이상 반복 패턴, 시행착오 끝 해결한 것 있었나?
- 있으면 → `~/.claude/skills/` 초안 생성 제안

A/B/C 후보 없으면 스킵.

---

## Step 3.5. CLAUDE.md 동기화 체크

이번 세션 변경이 있었다면:

| 변경 유형 | 확인 대상 |
|---|---|
| 경로/폴더 이동 | 해당 경로 하드코딩한 CLAUDE.md |
| 도구/에이전트 교체 | 해당 도구 참조한 CLAUDE.md |
| 역할/파이프라인 구조 변경 | 도메인 CLAUDE.md + 글로벌 |

수정 후 해당 CLAUDE.md 버전 날짜 갱신. 후보 없으면 스킵.

---

## Step 4. Obsidian 작업내역 기록

`$NEXUS_VAULT/02_Daily/작업/YYYY-MM-DD.md` 업데이트.

```markdown
## [프로젝트/도메인명]
- 완료한 것 (블로그 소재로 쓸 수 있는 수준)
- 결정사항/인사이트 있으면 포함
```

원칙: 완료한 것만 / 미완료는 checkpoint.json / 세션당 5~10줄 이내

---

## Step 5. 백그라운드 데몬 실행

위 단계 완료 후 데몬을 백그라운드로 실행:

```bash
# /save-restart 트리거인 경우
python3 ~/.claude/hooks/save_daemon.py --restart

# /save 트리거인 경우 (기본)
python3 ~/.claude/hooks/save_daemon.py
```

Bash 도구의 `run_in_background=true` 로 실행.
로그: `~/.claude/cache/save_daemon.log`

**데몬 처리 항목 (순서 보장):**
1. checkpoint.json snapshot 백업
2. checkpoint.json.prev → current diff → history.jsonl append (삭제 항목 → done/dropped/failed)
3. work-index.jsonl append
4. context git commit + push
5. sessions.db clean_exit 플래그
6. (--restart 시) bot-restart.sh 3초 후 실행 (git push 완료 후)

---

## Step 6. 종료 메시지

세션에서 완료한 작업 목록을 먼저 출력:

```
## 이번 세션 완료 작업
- <항목 1>
- <항목 2>
...
```

그 다음:

**세션 제목 변경 (자동):**
완료 항목 기반으로 제목 생성 후 `/rename` 실행.
```
형식: [스프린트ID] | [주요 완료 키워드]
예: SP-2026-W19 | token-opt 완료
예: SP-2026-W19 | BL-262 LaunchAgent
```
스프린트 없으면: `[도메인] | [핵심 작업]` 형식.

**Claude Code:** `/exit`
**Telegram:**
```
핸드오프 완료.
다음 액션: <checkpoint.json next>
<blocked 있으면: ⛔ 선행 조건: ...>
<restart 시: 30초 내 새 세션 시작>
```

---

## Failure Mode (단계별 실패 대응)

> 핵심 원칙: **어떤 단계가 실패해도 세션 종료를 차단하지 않는다.** 실패는 로그 + todo[]로만 기록.

| 단계 | 실패 조건 | 대응 |
| --- | --- | --- |
| Step 0.8 | 미완료 작업 발견 | blocked[]/todo[] 분류 후 계속 |
| Step 1 | checkpoint.json 없음 | 신규 생성으로 계속 |
| Step 2 | JSON 직렬화 오류 | .prev 유지, 오류 메시지 출력 후 계속 |
| Step 3 | candidates/ 디렉토리 없음 | 승격 체크 스킵 |
| Step 4 | Daily 파일 경로 없음 | mkdir -p 후 재시도 1회, 실패 시 스킵 |
| Step 5 | 데몬 실행 실패 | 로그 경로 출력 후 계속 (세션 종료 차단 안 함) |
| Step 5 | git push 실패 | 로컬 저장 완료로 간주, 다음 세션 push |
| Step 6 | /exit 미응답 | 수동 종료 안내 출력 |

**부분 실패 처리 패턴:**
```
Step N 실패 시:
  1. 오류 내용 → checkpoint.json todo[] 에 기록
  2. 다음 Step 계속 진행
  3. Step 6 종료 메시지에 "[⚠️ Step N 실패: <사유>]" 포함
```
