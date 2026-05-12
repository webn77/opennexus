#!/usr/bin/env bash
# Block file/path exploration via raw grep -r or find in home dirs.
# Claude should use /search skill instead.

CMD=$(jq -r '.tool_input.command // ""' 2>/dev/null)
[ -z "$CMD" ] && exit 0

BLOCK=0
HOME_PAT="(~/|$HOME/)(projects|obsidian-vault|context|\.claude)"

# grep with recursive flag (-r/-R/-rn/-rl etc.) targeting home directories
if echo "$CMD" | grep -qE "grep[^|;&]*-[a-zA-Z]*[rR][a-zA-Z]*[^|;&]*${HOME_PAT}"; then
  BLOCK=1
fi

# find starting from home directories
if echo "$CMD" | grep -qE "(^|[;&|]+\s*)find\s+${HOME_PAT}"; then
  BLOCK=1
fi

if [ "$BLOCK" = "1" ]; then
  jq -n '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": "파일·경로 탐색은 /search 스킬 먼저. 예: /search 키워드\n정당한 grep이면 특정 파일 절대경로로 지정: grep \"패턴\" /구체적/파일.md"
    }
  }'
  exit 0
fi

exit 0
