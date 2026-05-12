#!/usr/bin/env bash
# post-output-detect.sh
# Trigger : PostToolUse (Write|Edit)
# Blocking: false (async)
# 용도    : 03_Projects/ 산출물 MD 저장 감지 → 세션 flag 생성 (/goal 트리거용)

set -euo pipefail

INPUT=$(cat)
[[ -z "$INPUT" ]] && exit 0

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
case "$TOOL_NAME" in
    Write|Edit) ;;
    *) exit 0 ;;
esac

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
[[ -z "$FILE_PATH" ]] && exit 0
[[ "$FILE_PATH" != *.md ]] && exit 0

NEXUS_VAULT="${NEXUS_VAULT:-$HOME/obsidian-vault}"
PROJECTS_DIR="$NEXUS_VAULT/03_Projects"
[[ "$FILE_PATH" != "$PROJECTS_DIR"* ]] && exit 0

# 파일 존재 + type: frontmatter 확인
[[ ! -f "$FILE_PATH" ]] && exit 0
head -15 "$FILE_PATH" | grep -q '^type:' || exit 0

# 세션 flag 생성 (빈 파일 — /goal 트리거 신호)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"' 2>/dev/null)
FLAG="/tmp/review-flag-${SESSION_ID}"
touch "$FLAG"
exit 0
