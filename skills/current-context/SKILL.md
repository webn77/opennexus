---
name: current-context
description: 현재 작업 상태 확인 스킬. Use when user says now, 현재상황, 현재상황 확인해줘, 지금 뭐하고 있었지, 어디까지 했지, 뭐하고 있었어, 작업 이어서. DO NOT trigger for 저장해줘/세션 끝/정리하자/exit (→ handoff 스킬). DO NOT trigger when the user wants to save to a specific destination (e.g. 옵시디언에 저장, 파일로 저장) or asks about how to save files in a programming context.
---

# Current Context Skill

## 동작
1. ~/.nexus8/checkpoint.json 읽기 → 도메인 상태 + 멈춘 지점 + 다음 액션 요약
2. ~/.nexus8/backlog.json 읽기 → 현재 스프린트 상태 + 진행률 표시
   # backlog_backend 경유 — BACKLOG_BACKEND 설정으로 Linear/JSON 전환
   # import sys; sys.path.insert(0, str(Path.home()/"projects/work/nexus/backlog-os/agents"))
   # import backlog_backend as _bb
3. 글로벌 PO 전용 — 도메인 에이전트는 checkpoint.json domains.[도메인] 한 줄 + _pipeline/state/*.json 직접 확인

## 출력 포함 항목
- 도메인별 현황 (checkpoint.json)
- 다음 액션 / 블로커
- **스프린트 현황** (backlog.json):
  - 스프린트 번호/ID/주간
  - 진행률 바 [████░░░░░░] done/total
  - 진행 중 항목 top-3 (RICE 순)
  - 누적 스프린트 횟수

## 트리거
- now, 현재상황, 현재상황 확인해줘, 지금 뭐하고 있었지, 어디까지 했지, 뭐하고 있었어, 작업 이어서

## 트리거 제외
- 저장해줘, 세션 끝, 정리하자, exit → handoff 스킬
- 옵시디언에 저장, 파일로 저장 → 특정 대상 저장
- 코드에서 파일 저장하는 법 → 프로그래밍 질문
- 도메인 세션 (work/hire/analyze/design/study) → 실행 거부. "글로벌 PO 전용 스킬입니다. 현재상황은 checkpoint.json domains.[도메인] 한 줄 + _pipeline/state/*.json을 직접 확인하세요." 안내 후 종료

## 도메인 세션 현재상황 (work/hire/analyze/design/study)
스킬 대신 아래 순서로 직접 처리:
1. `~/.nexus8/checkpoint.json` 읽기 → `domains.[도메인]` 한 줄 + `todo[]` 중 해당 `[도메인]` 태그 항목만 표시
2. `~/projects/[도메인]/_pipeline/state/*.json` 확인 → pending[] 항목 표시
3. 다른 도메인 미결 항목은 표시하지 않음

---

## 이전 작업 검색 (요청 시에만)

**트리거**: "이전에 X 했었지", "언제 Y 작업했지", "X 관련 이전 작업", "작업 이력"

`~/.nexus8/work-index.jsonl` 에서 키워드 검색:

```bash
grep -i "<키워드>" ~/.nexus8/work-index.jsonl
```

결과 포맷:
```
## 이전 작업 검색: <키워드>
- YYYY-MM-DD: <summary>
  → 상세: $NEXUS_VAULT/<file>
```

원칙:
- 자동 로드 금지 — 요청 시에만
- 키워드 없으면 최근 5건: `tail -5 ~/.nexus8/work-index.jsonl`
