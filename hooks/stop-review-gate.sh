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

# retry 증가
jq --argjson r "$((RETRY + 1))" '.retry = $r' "$MARKER" > "${MARKER}.tmp" && mv "${MARKER}.tmp" "$MARKER"

# 잔여 마커 목록 수집
PENDING_COUNT=$(find "$HOME/context" -maxdepth 1 -name ".pending-review-*" 2>/dev/null | wc -l | tr -d ' ')

# 차단 — /goal 실행 지시
FILE_PATH_ESC="$FILE_PATH" MARKER_ESC="$MARKER" PENDING_COUNT_ESC="$PENDING_COUNT" \
python3 << 'PYEOF'
import json, os
file    = os.environ['FILE_PATH_ESC']
marker  = os.environ['MARKER_ESC']
count   = int(os.environ['PENDING_COUNT_ESC'])

reason = (
    f'검수 대기: {file} ({count}개 잔여)\n\n'
    '지금 즉시 /goal 스킬을 다음 완료 조건으로 실행하세요:\n\n'
    f'/goal ~/context/.pending-review-* 마커가 전부 사라질 때까지 반복 —'
    ' 각 마커 파일을 code-reviewer 서브에이전트로 검수,'
    ' PASS 시 마커 삭제, Stop 재시도'
)
print(json.dumps({'decision': 'block', 'reason': reason}, ensure_ascii=False))
PYEOF
exit 0
