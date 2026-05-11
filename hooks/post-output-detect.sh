#!/usr/bin/env bash
# post-output-detect.sh
# Trigger : PostToolUse (Write|Edit)
# Blocking: false (async)
# 용도    : 03_Projects/ 산출물 MD 저장 감지 → .pending-review-{session_id} 마커 생성

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

# 세션별 독립 마커
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"' 2>/dev/null)
MARKER="$HOME/context/.pending-review-${SESSION_ID}"
mkdir -p "$(dirname "$MARKER")"

# 기존 마커 확인
if [[ -f "$MARKER" ]]; then
    PREV_FILE=$(jq -r '.file // ""' "$MARKER" 2>/dev/null || echo "")

    if [[ "$PREV_FILE" == "$FILE_PATH" ]]; then
        # 동일 파일: retry 유지, ts만 갱신
        jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '.ts = $ts' "$MARKER" > "${MARKER}.tmp" \
            && mv "${MARKER}.tmp" "$MARKER"
        exit 0
    fi
    # 다른 파일: retry=0 리셋
fi

echo "{\"file\":\"$FILE_PATH\",\"retry\":0,\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$MARKER"
exit 0
