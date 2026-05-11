#!/usr/bin/env bash
# stop-review-gate.sh
# Trigger : Stop
# Blocking: true (decision: block)
# 용도    : 세션별 .pending-review-{session_id} 마커 있으면 종료 차단

set -uo pipefail

INPUT=$(cat)

# 세션별 독립 마커
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"' 2>/dev/null || echo "default")
MARKER="$HOME/context/.pending-review-${SESSION_ID}"

# 마커 없음 → 통과
[[ ! -f "$MARKER" ]] && exit 0

# 루프 방지: stop_hook_active=true → 통과
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
[[ "$STOP_HOOK_ACTIVE" == "true" ]] && exit 0

# 마커 파싱
FILE_PATH=$(jq -r '.file // ""' "$MARKER" 2>/dev/null || echo "")
RETRY=$(jq -r '.retry // 0' "$MARKER" 2>/dev/null || echo "0")

# 깨진 마커 → 자동 정리 후 통과
if [[ -z "$FILE_PATH" ]]; then
    rm -f "$MARKER"
    exit 0
fi

# retry >= 2 → 사용자 호출 단계, 통과
if [[ "$RETRY" -ge 2 ]]; then
    exit 0
fi

# 차단
printf '{"decision":"block","reason":"검수 대기: %s\n\nAgent 도구로 code-reviewer 서브에이전트를 스폰해 해당 파일을 검토하세요.\n검토 기준: frontmatter 완전성, 필수 섹션 존재, TODO/빈 섹션 없음.\nPASS 시 서브에이전트가 마커(%s)를 삭제합니다. FAIL 시 피드백을 사용자에게 보고하세요."}\n' "$FILE_PATH" "$MARKER"
exit 0
