---
name: checkpoint
description: 세션 중간 상태 저장 스킬. 종료 없이 checkpoint.json만 업데이트. Trigger when user says /checkpoint, 중간 저장, 체크포인트, 저장해줘 (세션 종료 없이).
---

# Checkpoint Skill
# v2.1 | 2026-04-17 | history.jsonl 연동 추가

세션을 종료하지 않고 현재 상태를 checkpoint.json에 저장합니다.
긴 세션에서 컨텍스트 압축 전 중요 결정을 보존할 때 사용.

## 실행

`~/.nexus8/checkpoint.json` 을 현재 세션 기준으로 갱신.

**수정할 필드:**
- `when`: 현재 시각 (ISO8601)
- `domains`: 변경된 도메인만 업데이트 (나머지 유지)
- `next`: 현재 작업 기준 다음 액션 1줄
- `blocked`: 외부 차단 항목 (변경 있을 때만)
- `todo`: 미완료 연관 작업 (새 항목 추가)

**원칙:**
- 2000자 캡 초과 시 todo[] 오래된 것 정리 후 저장
- next placeholder 금지

## 완료 이력 기록 (todo[] 항목 제거 시)

이전 checkpoint.json의 todo[]와 비교해 **제거된 항목**이 있으면 history.jsonl에 append:

```bash
source "$HOME/projects/_shared/history_utils.sh"
append_history "<domain>" "<item>" "done"
# status: done | failed | dropped
```

- `~/.nexus8/history.jsonl` — append-only, 삭제 금지
- 제거 이유가 완료가 아닌 경우: dropped (더 이상 불필요) / failed (실패)

## 완료 후

"💾 체크포인트 저장 완료 — 계속 작업합니다." 출력 후 대화 유지.
