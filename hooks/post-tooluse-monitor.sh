#!/usr/bin/env bash
# post-tooluse-monitor.sh
# Layer: 1 | Trigger: PostToolUse (전체) | Blocking: false
# 용도: 모든 툴 호출을 events.jsonl에 기록 — 세션 타임라인 + tool_count 집계용

export LANG=en_US.UTF-8

INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)

case "$TOOL_NAME" in
  "Skill")
    SKILL_NAME=$(echo "$INPUT" | jq -r '.tool_input.skill // "unknown"' 2>/dev/null)
    ~/.claude/hooks/log_event.sh "{\"type\":\"skill\",\"name\":\"${SKILL_NAME}\",\"session\":\"${SESSION_ID}\"}"
    ;;
  "Agent")
    SUBTYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // "general"' 2>/dev/null)
    DESC=$(echo "$INPUT" | jq -r '.tool_input.description // ""' 2>/dev/null | head -c 60 | tr '\n' ' ' | sed 's/"/\\"/g')
    ~/.claude/hooks/log_event.sh "{\"type\":\"agent_call\",\"subtype\":\"${SUBTYPE}\",\"detail\":\"${DESC}\",\"session\":\"${SESSION_ID}\"}"
    ;;
  "Bash")
    # description 우선 (사람이 읽기 좋은 요약), 없으면 command 앞 80자
    DETAIL=$(echo "$INPUT" | jq -r '.tool_input.description // ""' 2>/dev/null)
    if [ -z "$DETAIL" ]; then
      DETAIL=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null | head -c 80 | tr '\n' ' ')
    fi
    DETAIL=$(echo "$DETAIL" | head -c 120 | sed 's/"/\\"/g')
    ~/.claude/hooks/log_event.sh "{\"type\":\"tool\",\"name\":\"Bash\",\"detail\":\"${DETAIL}\",\"session\":\"${SESSION_ID}\"}"
    ;;
  "Read")
    FPATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
    FNAME=$(basename "$FPATH")
    ~/.claude/hooks/log_event.sh "{\"type\":\"tool\",\"name\":\"Read\",\"detail\":\"${FNAME}\",\"session\":\"${SESSION_ID}\"}"
    ;;
  "Edit"|"Write")
    FPATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
    FNAME=$(basename "$FPATH")
    ~/.claude/hooks/log_event.sh "{\"type\":\"tool\",\"name\":\"${TOOL_NAME}\",\"detail\":\"${FNAME}\",\"session\":\"${SESSION_ID}\"}"
    ;;
  "WebSearch")
    QUERY=$(echo "$INPUT" | jq -r '.tool_input.query // ""' 2>/dev/null | head -c 60 | sed 's/"/\\"/g')
    ~/.claude/hooks/log_event.sh "{\"type\":\"tool\",\"name\":\"WebSearch\",\"detail\":\"${QUERY}\",\"session\":\"${SESSION_ID}\"}"
    ;;
  "WebFetch")
    URL=$(echo "$INPUT" | jq -r '.tool_input.url // ""' 2>/dev/null | head -c 80 | sed 's/"/\\"/g')
    ~/.claude/hooks/log_event.sh "{\"type\":\"tool\",\"name\":\"WebFetch\",\"detail\":\"${URL}\",\"session\":\"${SESSION_ID}\"}"
    ;;
  "")
    ;;
  *)
    ~/.claude/hooks/log_event.sh "{\"type\":\"tool\",\"name\":\"${TOOL_NAME}\",\"session\":\"${SESSION_ID}\"}"
    ;;
esac

exit 0
